#
# Cookbook Name:: jruby
# Recipe:: default
#

package "dev-java/sun-jdk" do
  action :install
end

package "dev-java/jruby-bin" do
  action :install
end

execute "install-glassfish" do
  command "/usr/bin/jruby -S gem install glassfish"
end

#####
#
# Edit this to point to YOUR app's directory
#
#####

APP_DIRECTORY = '/data/hello_world/current'

#####
#
# These are generic tuning parameters for each instance size; you may want to further tune them for
# your application's specific needs if they prove inadequate.
# In particular, if you have a thread-safe application, you will _definitely_ only want a single
# runtime.
#
#####

size = `curl -s http://instance-data.ec2.internal/latest/meta-data/instance-type`
case size
when /m1.small/ # 1.7G RAM, 1 ECU, 32-bit
  JVM_CONFIG = '-server -Xmx1g -Xms1g -XX:MaxPermSize=256m -XX:PermSize=256m -XX:NewRatio=2  -XX:+DisableExplicitGC'
  JRUBY_RUNTIME_POOL_INITIAL = 1
  JRUBY_RUNTIME_POOL_MIN = 1
  JRUBY_RUNTIME_POOL_MAX = 1
when /m1.large/ # 1.7G RAM, 5 ECU, 32-bit
  JVM_CONFIG = '-server -Xmx1g -Xms1g -XX:MaxPermSize=256m -XX:PermSize=256m -XX:NewRatio=2  -XX:+DisableExplicitGC'
  JRUBY_RUNTIME_POOL_INITIAL = 1
  JRUBY_RUNTIME_POOL_MIN = 1
  JRUBY_RUNTIME_POOL_MAX = 5
when /m1.xlarge/ # 7.5G RAM, 4 ECU, 64-bit
  JVM_CONFIG = '-server -Xmx2.5g -Xms2.5g -XX:MaxPermSize=378m -XX:PermSize=378m =XX:NewRatio=2'
  JRUBY_RUNTIME_POOL_INITIAL = 1
  JRUBY_RUNTIME_POOL_MIN = 1
  JRUBY_RUNTIME_POOL_MAX = 5
when /c1.medium/ # 15G RAM, 8 ECU, 64-bit
  JVM_CONFIG = '-server -Xmx2.5g -Xms2.5g -XX:MaxPermSize=378m -XX:PermSize=378m =XX:NewRatio=2'
  JRUBY_RUNTIME_POOL_INITIAL = 1
  JRUBY_RUNTIME_POOL_MIN = 1
  JRUBY_RUNTIME_POOL_MAX = 8
when /c1.xlarge/ # 7.5G RAM, 20 ECU, 64-bit
  JVM_CONFIG = '-server -Xmx2.5g -Xms2.5g -XX:MaxPermSize=378m -XX:PermSize=378m =XX:NewRatio=2'
  JRUBY_RUNTIME_POOL_INITIAL = 1
  JRUBY_RUNTIME_POOL_MIN = 1
  JRUBY_RUNTIME_POOL_MAX = 20
else # This shouldn't happen, but do something rational if it does.
  JVM_CONFIG = '-server -Xmx1g -Xms1g -XX:MaxPermSize=256m -XX:PermSize=256m -XX:NewRatio=2  -XX:+DisableExplicitGC'
  JRUBY_RUNTIME_POOL_INITIAL = 1
  JRUBY_RUNTIME_POOL_MIN = 1
  JRUBY_RUNTIME_POOL_MAX = 1
end

template File.join([APP_DIRECTORY],'config','glassfish.yml') do
  owner node[:owner_name]
  group node[:owner_name]
  source 'glassfish.yml.erb'
  variables({
    :environment => 'development',
    :port => 3000,
    :contextroot => '/',
    :log_level => 3,
    :jruby_runtime_pool_initial => JRUBY_RUNTIME_POOL_INITIAL,
    :jruby_runtime_pool_min => JRUBY_RUNTIME_POOL_MIN,
    :jruby_runtime_pool_max => JRUBY_RUNTIME_POOL_MAX,
    :daemon_enable => 'true',
    :jvm_options => JVM_CONFIG
  })
end

execute "ensure-glassfish-is-running" do
  command "/usr/bin/jruby -S glassfish --config /data/hello_world/current/config/glassfish.yml  /data/hello_world/current"
  not_if "pgrep glassfish"
end
