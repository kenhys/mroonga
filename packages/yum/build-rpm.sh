#!/bin/sh

LANG=C

run()
{
  "$@"
  if test $? -ne 0; then
    echo "Failed $@"
    exit 1
  fi
}

rpmbuild_options=

. /vagrant/env.sh

distribution=$(cut -d " " -f 1 /etc/redhat-release | tr "A-Z" "a-z")
if grep -q Linux /etc/redhat-release; then
  distribution_version=$(cut -d " " -f 4 /etc/redhat-release)
else
  distribution_version=$(cut -d " " -f 3 /etc/redhat-release)
fi
distribution_version=$(echo ${distribution_version} | sed -e 's/\..*$//g')

architecture="$(arch)"
case "${architecture}" in
  i*86)
    architecture=i386
    ;;
esac

run yum groupinstall -y "Development Tools"
run yum install -y rpm-build rpmdevtools tar wget

if [ -x /usr/bin/rpmdev-setuptree ]; then
  rm -rf .rpmmacros
  run rpmdev-setuptree
else
  run cat <<EOM > ~/.rpmmacros
%_topdir ${HOME}/rpmbuild
EOM
  run mkdir -p ~/rpmbuild/SOURCES
  run mkdir -p ~/rpmbuild/SPECS
  run mkdir -p ~/rpmbuild/BUILD
  run mkdir -p ~/rpmbuild/RPMS
  run mkdir -p ~/rpmbuild/SRPMS
fi

repository="/vagrant/repositories/${distribution}/${distribution_version}"
rpm_dir="${repository}/${architecture}/Packages"
srpm_dir="${repository}/source/SRPMS"
run mkdir -p "${rpm_dir}" "${srpm_dir}"

rpmbuild_options=""

# for debug
# rpmbuild_options="${rpmbuild_options} --define 'optflags -O0 -g3'"

cd

run cp /vagrant/tmp/${PACKAGE}-${VERSION}.* rpmbuild/SOURCES/
run cp /vagrant/tmp/${distribution}/*.spec rpmbuild/SPECS/

package_name=$(cd rpmbuild/SPECS; echo *.spec | sed -e 's/\.spec$//g')

case ${distribution} in
  centos)
    release_rpm=groonga-release-latest.noarch.rpm
    run yum install -y \
        https://packages.groonga.org/${distribution}/${release_rpm}
    run yum makecache

    case ${package_name} in
      mysql5?-community-${PACKAGE})
        release_rpm=mysql-community-release-el${distribution_version}-7.noarch.rpm
        run yum -y install http://repo.mysql.com/${release_rpm}
        if [ "${package_name}" = "mysql57-community-${PACKAGE}" ]; then
          run yum install -y yum-utils
          run yum-config-manager --disable mysql56-community
          run yum-config-manager --enable mysql57-community
          if [ ${distribution_version} = 6 ]; then
            run yum install -y cmake28
          fi
        fi
        run yum install -y mysql-community-devel
        ;;
      mysql80-community-${PACKAGE})
        release_rpm=mysql80-community-release-el${distribution_version}.rpm
        run yum -y install http://repo.mysql.com/${release_rpm}
        run yum install -y centos-release-scl yum-utils autoconf-archive
        run yum-config-manager --enable rhel-server-rhscl-7-rpms
        run yum install -y cmake3 devtoolset-8-gcc devtoolset-8-gcc-c++
        run source /opt/rh/devtoolset-8/enable
        run yum install -y mysql-community-devel
        ;;
      mariadb-${PACKAGE})
        run yum install -y mariadb-devel
        ;;
      mariadb-10.*-${PACKAGE})
        mariadb_version=$(echo ${package_name} | cut -d '-' -f 2)
        if [ "${architecture}" = "x86_64" ]; then
          mariadb_architecture="amd64"
        else
          mariadb_architecture="x86"
        fi
        cat <<REPO > /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/${mariadb_version}/${distribution}${distribution_version}-${mariadb_architecture}
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
REPO
        run yum install -y MariaDB-devel
        if [ ${distribution_version} = 6 ]; then
          run yum install -y cmake28
        fi
        ;;
      percona-server-56-${PACKAGE})
        run yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
        run yum install -y Percona-Server-devel-56
        ;;
      percona-server-57-${PACKAGE})
        run yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
        run yum install -y Percona-Server-devel-57
        if [ ${distribution_version} = 6 ]; then
          run yum install -y cmake28
        fi
        ;;
    esac
    ;;
esac
run yum install -y ${DEPENDED_PACKAGES}

if [ "${package_name}" = "percona-server-56-${PACKAGE}" ]; then
  if [ "${distribution_version}" = "7" ]; then
    rpmbuild_options="$rpmbuild_options --define 'dist .el7'"
  fi
fi
if [ "${package_name}" = "percona-server-57-${PACKAGE}" ]; then
  if [ "${distribution_version}" = "7" ]; then
    rpmbuild_options="$rpmbuild_options --define 'dist .el7'"
  fi
fi
if [ "${USE_MYSQLSERVICES_COMPAT}" = "yes" ]; then
  rpmbuild_options="$rpmbuild_options --define 'mroonga_configure_options --with-libmysqlservices-compat'"
fi

run eval rpmbuild -ba ${rpmbuild_options} rpmbuild/SPECS/${package_name}.spec

run mv rpmbuild/RPMS/*/* "${rpm_dir}/"
run mv rpmbuild/SRPMS/* "${srpm_dir}/"
