classdef px4HostTarget_TCPIP_Read < matlab.System
    % px4HostTarget_TCPIP_Read 
    % Reads MAVLink bytes (HIL_ACTUATOR_CONTROLS) from PX4 Host Target over TCP port 4560.

    % Public, tunable properties
    properties
        % Data Length expected
        Length = 50
        % SampleTime Sample time
        SampleTime = -1;
    end

    properties(DiscreteState)
        PreviousValue
    end

    properties(Access = private)
        t
    end
    
    methods
        function obj = px4HostTarget_TCPIP_Read(varargin)
            coder.allowpcode('plain');
            setProperties(obj, nargin, varargin{:});
        end
        
        function set.SampleTime(obj, newTime)
            coder.extrinsic('error');
            coder.extrinsic('message');
            coder.allowpcode('plain');
            if (isLocked(obj) && obj.SampleTime ~= newTime)
                error(message('svd:svd:SampleTimeNonTunable'))
            end
           
            isOk = isreal(newTime) && ...
                (all(all(isfinite(newTime))) || all(all(isinf(newTime)))) && ...
                (numel(newTime) == 1 || numel(newTime) == 2);
            
            coder.internal.errorIf(~isOk, 'svd:svd:InvalidSampleTimeNeedScalar');
            if ~isreal(newTime)
                newTime = real(newTime);
            end
            
            coder.internal.errorIf((newTime(1) < 0.0 && newTime(1) ~= -1.0), 'svd:svd:InvalidSampleTimeNeedPositive');
            
            if numel(newTime) == 2
                coder.internal.errorIf((newTime(1) > 0.0 && newTime(2) >= newTime(1)), 'svd:svd:InvalidSampleTimeNeedSmallerOffset');
                coder.internal.errorIf((newTime(1) == -1.0 && newTime(2) ~= 0.0), 'svd:svd:InvalidSampleTimeNeedZeroOffset');
                coder.internal.errorIf((newTime(1) == 0.0 && newTime(2) ~= 1.0), 'svd:svd:InvalidSampleTimeNeedOffsetOne');
            end
            
            obj.SampleTime = newTime;
        end
        
        function set.Length(obj, value)
            classes = {'numeric'};
            attributes = {'nonempty', 'nonnan', 'real', 'nonnegative', 'nonzero', 'scalar'};
            validateattributes(value, classes, attributes, '', 'Expected Length');
            obj.Length = value;
        end
    end
    
    methods(Access = protected)
        function setupImpl(obj)
            obj.PreviousValue = uint8(zeros(obj.Length, 1));
            
            % Obtain the TCP server handle from singleton
            raw = px4HostTarget_tcpsingleton.getInstance();
            % Automatically unwrap if the singleton returned a wrapper class or struct
            if isprop(raw, 'Server') && ~isempty(raw.Server)
                obj.t = raw.Server;
            elseif isprop(raw, 't') && ~isempty(raw.t)
                obj.t = raw.t;
            else
                obj.t = raw;
            end
        end

        function [status, data] = stepImpl(obj)
            % Resolve underlying TCP object safely
            tcpObj = obj.t;
            if isprop(tcpObj, 'Server') && ~isempty(tcpObj.Server)
                tcpObj = tcpObj.Server;
            elseif isprop(tcpObj, 't') && ~isempty(tcpObj.t)
                tcpObj = tcpObj.t;
            end

            % Check available bytes across modern tcpserver and legacy tcpip
            dataLen = 0;
            if ~isempty(tcpObj)
                if isprop(tcpObj, 'NumBytesAvailable') || (isstruct(tcpObj) && isfield(tcpObj, 'NumBytesAvailable'))
                    dataLen = tcpObj.NumBytesAvailable;
                elseif isprop(tcpObj, 'BytesAvailable') || (isstruct(tcpObj) && isfield(tcpObj, 'BytesAvailable'))
                    dataLen = tcpObj.BytesAvailable;
                end
            end

            % Read if enough bytes are in the buffer
            if (dataLen >= obj.Length)
                try
                    obj.PreviousValue = uint8(read(tcpObj, obj.Length, "uint8")');
                    status = uint8(1);
                catch
                    status = uint8(0);
                end
            else
                status = uint8(0);
            end
            data = obj.PreviousValue;
        end

        function resetImpl(obj)
            obj.PreviousValue = uint8(zeros(obj.Length, 1));
        end
        
        function releaseImpl(obj)
            obj.t = [];
            px4HostTarget_tcpsingleton.getInstance('flush');
        end
    end
    
    methods(Access = protected)
        function num = getNumOutputsImpl(~)
            num = 2;
        end

        function varargout = getOutputNamesImpl(~)
            varargout{1} = 'Status';
            varargout{2} = 'Data';
        end
        
        function varargout = getOutputSizeImpl(obj)
            varargout{1} = [1 1];
            varargout{2} = [obj.Length 1];
        end

        function varargout = getOutputDataTypeImpl(~)
            varargout{1} = 'uint8';
            varargout{2} = 'uint8';
        end
        
        function varargout = isOutputComplexImpl(~)
            varargout{1} = false;
            varargout{2} = false;
        end

        function varargout = isOutputFixedSizeImpl(~)
            varargout{1} = true;
            varargout{2} = true;
        end
        
        function num = getNumInputsImpl(~)
            num = 0;
        end
        
        function st = getSampleTimeImpl(obj)
            if isequal(obj.SampleTime, -1) || isequal(obj.SampleTime, [-1, 0])
                st = matlab.system.SampleTimeSpecification('Type', 'Inherited');
            elseif isequal(obj.SampleTime, [0, 1])
                st = matlab.system.SampleTimeSpecification('Type', 'Fixed In Minor Step');
            else
                if numel(obj.SampleTime) == 1
                    sampleTime = obj.SampleTime;
                    offset = 0;
                else
                    sampleTime = obj.SampleTime(1);
                    offset = obj.SampleTime(2);
                end
                st = matlab.system.SampleTimeSpecification('Type', 'Discrete', ...
                    'SampleTime', sampleTime, 'Offset', offset);
            end
        end
        
        function [sz, dt, cp] = getDiscreteStateSpecificationImpl(obj, name)
            if strcmp(name, 'PreviousValue')
                sz = [obj.Length 1];
                dt = 'uint8';
                cp = false;
            else
                error(['Error: Incorrect State Name: ', name]);
            end
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            num = 2;
            outport_label = [];
            outputs = getOutputNames(obj);
            for i = 1:num
                outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' newline];
            end
            
            LocalIPPort = ['sprintf(''Port: %d'',' num2str(uint32(4560)) ')'];
            
            maskDisplayCmds = [ ...
                ['color(''white'');', newline] ...
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);', newline] ...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);', newline] ...
                ['color(''black'');', newline] ...
                ['text(50,50,''TCP Read'',''horizontalAlignment'',''center'');', newline] ...
                ['text(50,12,' LocalIPPort ' ,''horizontalAlignment'', ''center'');', newline], ...
                outport_label
            ];
        end
    end
    
    methods (Static, Access = protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end

    methods(Static, Access = protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'), ...
                'ShowSourceLink', false, ...
                'Title', 'TCP Read from PX4 Host Target', ...
                'Text', ['This TCP connection is in Server mode on Port 4560.' newline newline ...
                'The Data port outputs the values received as an [Nx1] array.' newline newline ...
                'The Status port outputs 0 when the available data size is less than the expected length.']);
        end
    end
    
    methods
        function newTime = validateSampleTime(~, newTime)
            coder.allowpcode('plain');
            isOk = isreal(newTime) && ...
                (all(all(isfinite(newTime))) || all(all(isinf(newTime)))) && ...
                (numel(newTime) == 1 || numel(newTime) == 2);
            
            coder.internal.errorIf(~isOk, 'svd:svd:InvalidSampleTimeNeedScalar');
            if ~isreal(newTime)
                newTime = real(newTime);
            end
            
            coder.internal.errorIf((newTime(1) < 0.0 && newTime(1) ~= -1.0), 'svd:svd:InvalidSampleTimeNeedPositive');
            
            if numel(newTime) == 2
                coder.internal.errorIf((newTime(1) > 0.0 && newTime(2) >= newTime(1)), 'svd:svd:InvalidSampleTimeNeedSmallerOffset');
                coder.internal.errorIf((newTime(1) == -1.0 && newTime(2) ~= 0.0), 'svd:svd:InvalidSampleTimeNeedZeroOffset');
                coder.internal.errorIf((newTime(1) == 0.0 && newTime(2) ~= 1.0), 'svd:svd:InvalidSampleTimeNeedOffsetOne');
            end
        end
    end
end
