user "app" do
  create_home true
end

directory "/home/app" do
  user "app"
end

['sudo', 'adm', 'dialout', 'audio', 'plugdev', 'users', 'input', 'netdev'].each do |group|
  execute "add sudo group at %s" % group do
    only_if "id app"
    command "usermod app -aG %s" % group
  end
end

package "vim"
remote_file "/home/app/.vimrc" do
  user "app"
end

# mochi
package "mpd"
package "mpc"
remote_file "/etc/mpd.conf"

package "alsa-utils"
package "pulseaudio"
package "pulseaudio-utils"
package "pulsemixer"

directory "/home/app/.config" do
  user "app"
end

directory "/home/app/.config/pulse" do
  user "app"
end

remote_file "/home/app/.config/pulse/client.conf" do
  user "app"
end

remote_file "/home/app/.config/pulse/daemon.conf" do
  user "app"
end

remote_file "/home/app/.config/pulse/default.pa" do
  user "app"
end

remote_file "/home/app/.config/pulse/system.pa" do
  user "app"
end


# nginx
package "nginx"
remote_file "/etc/nginx/nginx.conf" do
  user "root"
  mode "755"
end
remote_file "/etc/nginx/sites-available/default" do
  user "root"
  mode "755"
end
remote_file "/etc/nginx/sites-enabled/default" do
  user "root"
  mode "755"
end
directory "/var/lib/nginx" do
  mode "775"
end


# 無理
#execute "pulseaudio.socket" do
#user "app"
#  command "systemctl --user enable pulseaudio.socket"
#end

execute "autostart systemd user instance" do
  command "loginctl enable-linger app"
end
