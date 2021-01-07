#!/bin/sh

if [ "$AWS_EXECUTION_ENV" != "" ]; then # We're in AWS
  [ "$profiledata_pubkey" = "" ] && echo "profiledata_pubkey not provided!"
  [ "$profiledata_ssh_host_rsa_key" = "" ] && echo "profiledata_ssh_host_rsa_key not provided!"
  [ "$profiledata_ssh_host_rsa_pubkey" = "" ] && echo "profiledata_ssh_host_rsa_pubkey not provided!"
  [ "$profiledata_ssh_host_ed25519_key" = "" ] && echo "profiledata_ssh_host_ed25519_key not provided!"
  [ "$profiledata_ssh_host_ed25519_pubkey" = "" ] && echo "profiledata_ssh_host_ed25519_pubkey not provided!"
  [ "$profiledata_ssh_host_ecdsa_key" = "" ] && echo "profiledata_ssh_host_ecdsa_key not provided!"
  [ "$profiledata_ssh_host_ecdsa_pubkey" = "" ] && echo "profiledata_ssh_host_ecdsa_pubkey not provided!"
  [ "$profiledata_ssh_host_dsa_key" = "" ] && echo "profiledata_ssh_host_dsa_key not provided!"
  [ "$profiledata_ssh_host_dsa_pubkey" = "" ] && echo "profiledata_ssh_host_dsa_pubkey not provided!"

  echo "$profiledata_ssh_host_rsa_key" >/etc/ssh/ssh_host_rsa_key
  echo "$profiledata_ssh_host_rsa_pubkey" >/etc/ssh/ssh_host_rsa_key.pub

  echo "$profiledata_ssh_host_ed25519_key" >/etc/ssh/ssh_host_ed25519_key
  echo "$profiledata_ssh_host_ed25519_pubkey" >/etc/ssh/ssh_host_ed25519_key.pub

  echo "$profiledata_ssh_host_ecdsa_key" >/etc/ssh/ssh_host_ecdsa_key
  echo "$profiledata_ssh_host_ecdsa_pubkey" >/etc/ssh/ssh_host_ecdsa_key.pub

  echo "$profiledata_ssh_host_dsa_key" >/etc/ssh/ssh_host_dsa_key
  echo "$profiledata_ssh_host_dsa_pubkey" >/etc/ssh/ssh_host_dsa_key.pub
  chmod 600 /etc/ssh/ssh_host*

  mkdir -p /home/couchbase/.ssh
  echo "$profiledata_pubkey" >/home/couchbase/.ssh/authorized_keys

  for subdir in cv/macos/.ssh shared/.ssh cv/linux/.ssh build/linux/.ssh build/windows/.ssh; do
    mkdir -p "/home/couchbase/couchbase-server/$subdir"
  done

  echo "$couchbase_server_shared_gitconfig" >/home/couchbase/couchbase-server/shared/.gitconfig
  echo "$couchbase_server_shared_ssh_environment" >/home/couchbase/couchbase-server/shared/.ssh/environment
  echo "$couchbase_server_linux_cv_ssh_config" >/home/couchbase/couchbase-server/cv/linux/.ssh/config
  echo "$couchbase_server_macos_cv_ssh_config" >/home/couchbase/couchbase-server/cv/macos/.ssh/config

  # couchbase-server / windows / build
  echo "$couchbase_server_windows_config" >/home/couchbase/couchbase-server/build/windows/.ssh/config
  echo "$couchbase_server_windows_environment" >/home/couchbase/couchbase-server/build/windows/.ssh/environment
  echo "$couchbase_server_windows_authorized_keys" >/home/couchbase/couchbase-server/build/windows/.ssh/authorized_keys

  # couchbase-server / windows / cv
  mkdir -p /home/couchbase/couchbase-server/cv/windows/.ssh
  echo "$couchbase_server_cv_windows_gitconfig" >/home/couchbase/couchbase-server/cv/windows/.gitconfig
  echo "$couchbase_server_cv_windows_ssh_buildbot_id_dsa" >/home/couchbase/couchbase-server/cv/windows/.ssh/buildbot_id_dsa
  echo "$couchbase_server_cv_windows_ssh_config" >/home/couchbase/couchbase-server/cv/windows/.ssh/config
  echo "$couchbase_server_cv_windows_ssh_config_org" >/home/couchbase/couchbase-server/cv/windows/.ssh/config.org
  echo "$couchbase_server_cv_windows_ssh_environment" >/home/couchbase/couchbase-server/cv/windows/.ssh/environment
  echo "$couchbase_server_cv_windows_ssh_id_ns_codereview" >/home/couchbase/couchbase-server/cv/windows/.ssh/id_ns-codereview
  echo "$couchbase_server_cv_windows_ssh_id_rsa" >/home/couchbase/couchbase-server/cv/windows/.ssh/id_rsa
  echo "$couchbase_server_cv_windows_ssh_known_hosts" >/home/couchbase/couchbase-server/cv/windows/.ssh/known_hosts
  echo "$couchbase_server_cv_windows_ssh_ns_buildbot_rsa" >/home/couchbase/couchbase-server/cv/windows/.ssh/ns-buildbot.rsa
  echo "$couchbase_server_cv_windows_ssh_patch_via_gerrit_ini" >/home/couchbase/couchbase-server/cv/windows/.ssh/patch_via_gerrit.ini

  # couchbase-server / linux / build
  mkdir /home/couchbase/couchbase-server/build/linux/.gpg/
  mkdir /home/couchbase/couchbase-server/build/linux/.m2/
  echo "$couchbase_server_build_linux_gitconfig" >/home/couchbase/couchbase-server/build/linux/.gitconfig
  echo "$couchbase_server_build_linux_gpg_rpm_signing" | base64 -d >/home/couchbase/couchbase-server/build/linux/.gpg/rpm_signing
  chmod 600 /home/couchbase/couchbase-server/build/linux/.gpg/rpm_signing
  # echo "$couchbase_server_build_linux_m2_settings_xml" >/home/couchbase/couchbase-server/build/linux/.m2/settings.xml
  echo "$couchbase_server_build_linux_ssh_config" >/home/couchbase/couchbase-server/build/linux/.ssh/config
  echo "$couchbase_server_build_linux_ssh_environment" >/home/couchbase/couchbase-server/build/linux/.ssh/environment
  echo "$couchbase_server_build_linux_ssh_id_buildbot" >/home/couchbase/couchbase-server/build/linux/.ssh/id_buildbot
  chmod 600 /home/couchbase/couchbase-server/build/linux/.ssh/id_buildbot
  echo "$couchbase_server_build_linux_ssh_id_cb_robot" >/home/couchbase/couchbase-server/build/linux/.ssh/id_cb-robot
  chmod 600 /home/couchbase/couchbase-server/build/linux/.ssh/id_cb-robot
  echo "$couchbase_server_build_linux_ssh_id_ns_codereview" >/home/couchbase/couchbase-server/build/linux/.ssh/id_ns-codereview
  chmod 600 /home/couchbase/couchbase-server/build/linux/.ssh/id_ns-codereview
  echo "$couchbase_server_build_linux_ssh_known_hosts" >/home/couchbase/couchbase-server/build/linux/.ssh/known_hosts
  echo "$couchbase_server_build_linux_ssh_notarizer_token" >/home/couchbase/couchbase-server/build/linux/.ssh/notarizer_token
  chmod 600 /home/couchbase/couchbase-server/build/linux/.ssh/notarizer_token
  echo "$couchbase_server_build_linux_ssh_ns_buildbot_rsa" >/home/couchbase/couchbase-server/build/linux/.ssh/ns-buildbot.rsa
  chmod 600 /home/couchbase/couchbase-server/build/linux/.ssh/ns-buildbot.rsa
  echo "$couchbase_server_build_linux_ssh_ns_patch_via_gerrit_ini" >/home/couchbase/couchbase-server/build/linux/.ssh/patch_via_gerrit.ini
  chmod 600 /home/couchbase/couchbase-server/build/linux/.ssh/patch_via_gerrit.ini

  # couchbase-server / linux / cv
  mkdir /home/couchbase/couchbase-server/cv/linux/.m2/
  echo "$couchbase_server_cv_linux_gitconfig" >/home/couchbase/couchbase-server/cv/linux/.gitconfig
  # echo "$couchbase_server_cv_linux_m2_settings_xml" >/home/couchbase/couchbase-server/cv/linux/.m2/settings.xml
  echo "$couchbase_server_cv_linux_ssh_config" >/home/couchbase/couchbase-server/cv/linux/.ssh/config
  echo "$couchbase_server_cv_linux_ssh_id_ns_codereview" >/home/couchbase/couchbase-server/cv/linux/.ssh/id_ns-codereview
  chmod 600 /home/couchbase/couchbase-server/cv/linux/.ssh/id_ns-codereview
  echo "$couchbase_server_cv_linux_ssh_known_hosts" >/home/couchbase/couchbase-server/cv/linux/.ssh/known_hosts
  echo "$couchbase_server_cv_linux_ssh_ns_buildbot_rsa" >/home/couchbase/couchbase-server/cv/linux/.ssh/ns-buildbot.rsa
  chmod 600 /home/couchbase/couchbase-server/cv/linux/.ssh/ns-buildbot.rsa
  echo "$couchbase_server_cv_linux_ssh_patch_via_gerrit_ini" >/home/couchbase/couchbase-server/cv/linux/.ssh/patch_via_gerrit.ini
  chmod 600 /home/couchbase/couchbase-server/cv/linux/.ssh/patch_via_gerrit.ini
  echo "$couchbase_server_cv_linux_ssh_id_buildbot" >/home/couchbase/couchbase-server/cv/linux/.ssh/id_buildbot
  chmod 600 /home/couchbase/couchbase-server/cv/linux/.ssh/id_buildbot
  echo "$couchbase_server_cv_linux_ssh_environment" >/home/couchbase/couchbase-server/cv/linux/.ssh/environment
  echo "$couchbase_server_cv_linux_ssh_buildbot_id_dsa" >/home/couchbase/couchbase-server/cv/linux/.ssh/buildbot_id_dsa
  chmod 600 /home/couchbase/couchbase-server/cv/linux/.ssh/buildbot_id_dsa

  chown -R couchbase:couchbase /home/couchbase
fi

exec $@
