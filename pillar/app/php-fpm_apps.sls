{% set client = '' %}
{% set hostname = '' %}

{% set domain_301 = '' %}
{% set domain = '' %}

{% set appname = '' %}
{% set apppass = '' %}

{% set mysqlpass = '' %}

{% set phpver = '7.2' %}

{% set sftp_user = 'sftp_' ~ appname %}
{% set sftp_pass = '' %}

{% set approot = '/var/www/' ~ appname %}
{% set appdir = approot ~ '/app' %}
{% set logdir = appdir ~ '/logs' %}



proftpd:
  users:
    {{ sftp_user }}:
      password: {{ sftp_pass }}
      homedir: {{ appdir }}
      makedir: False
      user: {{ appname }}
      group: {{ appname }}


percona:
  databases:
    {{ appname }}:
  users:
    {{ appname }}:
      host: localhost
      password: '{{ mysqlpass }}'
      databases:
        - database: {{ appname }}
          grant: ['all privileges']

app:
  php-fpm_apps:
    {{ appname }}:
      enabled: True
      user: '{{ appname }}'
      group: '{{ appname }}'
      pass: '{{ apppass }}'
      enforce_password: True
      app_root: {{ approot }}
      app_auth_keys: |
      shell: '/bin/bash'
      nginx:
        link_sites-enabled: True
        reload: False
        vhost_config: 'app/{{ client }}/{{ hostname }}/{{ appname }}/vhost.conf'
        root: '{{ appdir }}/src'
        server_name: '{{ domain }}'
        server_name_301: '{{ domain_301 }}'
        access_log: '{{ logdir }}/nginx/{{ appname }}.access.log'
        error_log: '{{ logdir }}/nginx/{{ appname }}.error.log'
        log:
          dir: '{{ logdir }}/nginx'
        ssl:
          acme: True
      pool:
        pool_config: 'app/{{ client }}/{{ hostname }}/{{ appname }}/pool.conf'
        reload: False
        log:
          dir: '{{ logdir }}'
        php_version: '{{ phpver }}'
        pm: |
          pm = dynamic
          pm.max_children = 50
          pm.start_servers = 2
          pm.min_spare_servers = 2
          pm.max_spare_servers = 6
        php_admin: |
          php_admin_value[error_log] = {{ logdir }}/{{ phpver }}-fpm/{{ appname }}.error.log
          php_admin_value[upload_max_filesize] = 100M
          php_admin_value[post_max_size] = 100M
          request_terminate_timeout = 300
          php_admin_flag[html_errors] = off
          php_admin_flag[log_errors] = on
          php_flag[display_errors] = off
          php_admin_value[memory_limit] = 512M
