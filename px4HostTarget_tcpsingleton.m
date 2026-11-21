classdef px4HostTarget_tcpsingleton < handle
    % px4HostTarget_tcpsingleton
    % Singleton manager for TCP Server on port 4560 used by PX4 SITL / Simulink plant.

    properties
        Server
    end

    methods (Static)
        function s = getInstance(action)
            persistent instance;

            % Handle flush command on releaseImpl
            if nargin > 0 && (strcmpi(action, 'flush') || strcmpi(action, 'close') || strcmpi(action, 'delete'))
                if ~isempty(instance) && isvalid(instance) && ~isempty(instance.Server) && isvalid(instance.Server)
                    try
                        flush(instance.Server);
                    catch
                    end
                end
                s = [];
                return;
            end

            % Create server if not already running
            if isempty(instance) || ~isvalid(instance) || isempty(instance.Server) || ~isvalid(instance.Server)
                instance = px4HostTarget_tcpsingleton();
                port = 4560;

                % Clean up lingering sockets on port 4560
                try
                    existing = tcpserverfind("ServerPort", port);
                    delete(existing);
                catch
                end

                % Create new server listening for PX4 client
                try
                    instance.Server = tcpserver("0.0.0.0", port);
                catch
                    try
                        instance.Server = tcpserver("127.0.0.1", port);
                    catch ME
                        error('Could not create TCP server on port %d: %s', port, ME.message);
                    end
                end
            end

            % Return the tcpserver object directly
            s = instance.Server;
        end
    end
end