classdef px4HostTarget_TCPIP_Write < matlab.System
    % px4HostTarget_TCPIP_Write
    % Writes MAVLink byte stream (HIL_SENSOR, HIL_GPS, HIL_STATE_QUATERNION, HEARTBEAT)
    % to PX4 Host Target over TCP port 4560.

    properties(Access = private)
        t
    end

    methods
        function obj = px4HostTarget_TCPIP_Write(varargin)
            coder.allowpcode('plain');
            setProperties(obj, nargin, varargin{:});
        end
    end

    methods(Access = protected)
        function setupImpl(obj)
            % Obtain TCP server handle from singleton
            raw = px4HostTarget_tcpsingleton.getInstance();
            if isprop(raw, 'Server') && ~isempty(raw.Server)
                obj.t = raw.Server;
            elseif isprop(raw, 't') && ~isempty(raw.t)
                obj.t = raw.t;
            else
                obj.t = raw;
            end
        end

        function stepImpl(obj, u)
            % Resolve underlying TCP object
            tcpObj = obj.t;
            if isprop(tcpObj, 'Server') && ~isempty(tcpObj.Server)
                tcpObj = tcpObj.Server;
            elseif isprop(tcpObj, 't') && ~isempty(tcpObj.t)
                tcpObj = tcpObj.t;
            end

            if isempty(tcpObj)
                return;
            end

            % Only write if a client (PX4) is actively connected
            isConnected = false;
            if isprop(tcpObj, 'Connected')
                isConnected = logical(tcpObj.Connected);
            elseif isprop(tcpObj, 'Status')
                isConnected = strcmpi(tcpObj.Status, 'open');
            end

            if isConnected
                try
                    write(tcpObj, u, "uint8");
                catch
                end
            end
        end

        function releaseImpl(obj)
            obj.t = [];
        end

        function num = getNumInputsImpl(~)
            num = 1;
        end

        function num = getNumOutputsImpl(~)
            num = 0;
        end
    end

    methods (Static, Access = protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
    end
end
