@dir = "/home/pi/ruby/sinatra/rubypi/"

worker_processes 2
working_directory @dir

timeout 30

listen "#{@dir}tmp/sockets/unicorn.sock", :backlog => 64

pid "#{@dir}tmp/pids/unicorn.pid"

stderr_path "#{@dir}logs/unicorn.stderr.log"
stdout_path "#{@dir}logs/unicorn.stdout.log"