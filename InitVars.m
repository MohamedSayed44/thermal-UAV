%% InitVars.m - Quadcopter Plant Parameters Initialization
%clearvars -except bdroot;

% Simulation & timing
SampleTime = 0.005; % 200 Hz loop rate
g = 9.80665;        % Gravity (m/s^2)

% Physical properties (jMAVSim default X-quad frame)
mass = 1.0; % Vehicle mass (kg)
inertia = diag([0.0082, 0.0084, 0.016]); % Inertia matrix (kg*m^2)
aMode = 0;

% Initial conditions [NED]
init.posNED = [0; 0; 0];
init.vb     = [0; 0; 0];
init.euler  = [0; 0; 0];
init.angRates = [0; 0; 0];
Vehicle.SixDOF.quatGain = 1.0;

% Rotor positions [X, Y, Z] relative to CG (meters)
% Standard X-configuration (FR, RL, FL, RR)
armLength = 0.175;
rotorPositions = [ armLength*cos(pi/4), -armLength*sin(pi/4), 0;  % Rotor 1 (Front-Right)
                  -armLength*cos(pi/4),  armLength*sin(pi/4), 0;  % Rotor 2 (Rear-Left)
                   armLength*cos(pi/4),  armLength*sin(pi/4), 0;  % Rotor 3 (Front-Left)
                  -armLength*cos(pi/4), -armLength*sin(pi/4), 0]'; % Rotor 4 (Rear-Right)

% Rotor spin directions: +1 (CCW), -1 (CW)
rotorDir = [-1; -1; 1; 1];

% Rotor dynamics limits
rotorThrustMax = 5.0;  % Max thrust per motor (N)
rotorTorqueMax = 0.05; % Max motor torque (N*m)
rotorTimeConst = 0.05; % Motor time constant (s)

% Aerodynamics
windVel = [0; 0; 0];
dragCoeffMov = diag([0.1, 0.1, 0.2]);

% Ground contact model parameters (soft Coulomb contact)
contact.translation.spring   = 1000;
contact.translation.damper   = 50;
contact.translation.friction = 0.5;
contact.translation.vd       = 0.01;

contact.rotation.spring   = 100;
contact.rotation.damper   = 10;
control.rotation.friction = 0.5;
control.rotation.vd       = 0.01;

% Ground contact model parameters (soft Coulomb contact)
contact.translation.spring      = 1000;
contact.translation.damper      = 50;
contact.translation.friction    = 0.5;
contact.translation.vd          = 0.01;
contact.translation.maxFriction = 50;   % Max friction force (N)
contact.translation.maxNormal   = 100;  % Max normal force (N)

contact.rotation.spring         = 100;
contact.rotation.damper         = 10;
control.rotation.friction       = 0.5;
control.rotation.vd             = 0.01;
control.rotation.maxMoment      = 10;   % Max contact moment (N*m)
% GPS Reference Coordinates (Origin: Lat, Lon, Altitude)
ref_lat    = 47.397742;  % Default PX4 Zurich home lat
ref_lon    = 8.545594;   % Default PX4 Zurich home lon
ref_height = 488.0;      % Altitude (m)

% Unit conversion constants
m_to_mm  = 1000;
ms_to_cms = 100;
ms2_to_mg = 1000 / g;