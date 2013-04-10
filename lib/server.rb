require 'socket'
require_relative 'client'

module IRCNotify
  class Server
    def initialize bridge
      @bridge = bridge
      if File.socket? Config::Server::PATH then File.delete Config::Server::PATH end
      @unix_server = UNIXServer.new Config::Server::PATH
      @clients = []
    end
    def start
      while socket = @unix_server.accept do
        client = Client.new @bridge, socket
        Thread.new do
          @clients << client
          begin
            client.start_read
          rescue StandardError => error
            IRCNotify.log "Client error: #{error}", :error
          end
          @clients.delete client
        end
      end
    end
    def stop
      path = @unix_server.path
      @unix_server.shutdown
      @unix_server = nil
      File.delete path
    end
    def send at, from, cmd
      trigger, msg = cmd.split ' ', 2
      if trigger
        @clients.each do |c| c.send at, from, trigger, msg end
      else
        @bridge.irc_send NAME, "#{VERSION} listening on #{HOST}:#{@unix_server.path}"
      end
    end
  end
end
