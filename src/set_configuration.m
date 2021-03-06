%%% "Distance-Ring Exponential Stations Generator (DRESG) for LPWANs"
%%% Author: Sergio Barrachina (sergio.barrachina@upf.edu)
%%% More info at S. Barrachina, B. Bellalta, T. Adame, and A. Bel, ?Multi-hop Communication in the Uplink for LPWANs,? 
%%% arXiv preprint arXiv:1611.08703, 2016.
%%%
%%% File description: script for setting the DRESG configuration for
%%% posterior analysis.

% Close opened figures and clear workspace variables
clc
clear
close all

%% Fixed constants (DO NOT CHANGE THIS!)
ROUTING_MODEL_SINGLE_HOP = 0;       % Single-hop routing model
ROUTING_MODEL_NEXT_RING_HOP = 1;    % Next-ring-hop routing model
ROUTING_MODEL_OPTIMAL_HOP = 2;      % Optimal-hop routing model

RESULTS_NUM_ELEMENTS = 11;          % Number of elements in the 'results' array
RESULTS_IX_ENERGY_TX = 1;           % Index of the energy consumed with optimal configuration
RESULTS_IX_POWER_OPT = 2;           % Index of the optimal transmission power
RESULTS_IX_POWER_LVL = 3;           % Index of the optimal transmission power level  
RESULTS_IX_R_OPT = 4;               % Index of the optimal rate
RESULTS_IX_R_LVL = 5;               % Index of the optimal rate level
RESULTS_IX_ENERGY_RX = 6;           % Index of the receiving energy
RESULTS_IX_RING_LOAD = 7;           % Index of the average number of payloads to be sent per STA
RESULTS_IX_MAX_RING_LOAD = 8;       % Index of the maximum number of payloads to be sent per STA (when PER = 0)
RESULTS_IX_DFS_RING_LOAD = 9;       % Index of the average number of DFS to be sent per STA
RESULTS_IX_RING_DESTIINATION = 10;  % Index of the the destination ring
RESULTS_IX_NUM_PACKETS_RX = 11;     % Index of the the destination ring

TRANSCEIVER_MODEL_CC1100 = 0;       % CC1100 transceiver model
TRANSCEIVER_MODEL_CC1200 = 1;       % CC1100 transceiver model
TRANSCEIVER_MODEL_SI4464 = 2;       % Si4464 (SigFox) transceiver model
TRANSCEIVER_MODEL_SX1272 = 3;       % SX1272/73 (LoRa) transceiver model

PROPAGATION_MODEL_FREE_SPACE = 0;   % Free space propagation model
PROPAGATION_MODEL_URBAN_MACRO = 1;  % 802.11 Urban macro deployment propagation model
PROPAGATION_MODEL_PICO = 2;         % 802.11 Pico/hotzone propagation model

RING_SPREAD_MODEL_EQUIDISTANT = 0;          % Equidistant ring spread model
RING_SPREAD_MODEL_FIBONACCI = 1;            % Fibonacci ring spread model
RING_SPREAD_MODEL_INVERSE_FIBONACCI = 2;    % Inverse Fibonacci ring spread model

% Learning: https://en.wikipedia.org/wiki/Multi-armed_bandit
EPSILON_GREEDY_CONSTANT = 0;
EPSILON_GREEDY_DECREASING = 1;

%% Main configuration parameters (EDITABLE)

plot_topology = false;               % Flag for plotting the DRESG topology. Too crowded LPWANs may not be properly represented.
plot_ring_spread = false;            % Flag for plotting the ring locations

num_rings = 3;                     % Num of rings of the DRESG deployment (a.k.a R)
child_ratio = 8;                    % Num of children of STAs not belonging to the last ring
spread_model = RING_SPREAD_MODEL_EQUIDISTANT;   % Equidistant, fibonacci or reverse fibonnaci
transceiver_model = TRANSCEIVER_MODEL_CC1200;   % Transceiver model

L_DP = 65;                          % Fixed data packet length [Bytes]
L_payload = 15;                     % Fixed payload length [Bytes]
L_header = 2;                       % Fixed ENTOMATIC header length [Bytes]
V = 3;                              % STAs nominal voltage [V]
f = 868e6;                          % Carrier frequency [Hz]
c = 3e8;                            % Speed of light [m/s]
lambda = c/f;                       % Propagation wavelength [m]
Grx = 3;                            % Receiver gain [dBi]
Gtx = 0;                            % Transmitter gaint [dBi]
No = -200.93;                       % Noise power density
prop_model = PROPAGATION_MODEL_URBAN_MACRO; % Propagation model
fibo_stress = 1;                    % First fibonnaci number to consider


%%  Load configuration parameters

disp('Saving DRESG deployment and scenarion configuration...')

% Packets

if (L_payload + L_header) > L_DP
    error('Packet lenght greater than L_DP! Check L_payload, L_header')
end
p_ratio = floor ((L_DP - L_header) / L_payload);    % Max num of payloads in a data packet

% Packet/Bit error rates
% PER=0.1;                        % Packet error rate
% BER=1-(1-PER)^(1/(DFS*8));      % Bit error rate

% PHY layer and propagation
switch prop_model
    case PROPAGATION_MODEL_FREE_SPACE
        prop_model_str = 'Free space';
    case PROPAGATION_MODEL_URBAN_MACRO
        prop_model_str = '802.11 Urban macro deployment';
    case PROPAGATION_MODEL_PICO
        prop_model_str = '802.11 Pico/hotzone deployment';
    otherwise
        error('Propagation model unknown!');
end

%% TRANSCEIVER HARDWARE 
switch transceiver_model
    
    case TRANSCEIVER_MODEL_CC1100
        transceiver_model_str = 'CC1100';
        P_LVL = [10 7 5 0 -5 -10 -15 -20 -30];  % STAs TX output power at 868 MHz [dBm]
        I_LVL = [31.1 25.8 20.0 16.9 14.1 14.5 13.0 12.4 11.9]; % STAs TX current [mA]
        I_rx = 14.4;    % STAs RX current [mA]
        R_LVL = [1.2e3 38.4e3 250e3 500e3]; % Rate levels [bps]
        S = [-110 -103 -93 -88];   % Sensitivity [dBm] for each rate level
    
    case TRANSCEIVER_MODEL_CC1200
        transceiver_model_str = 'CC1200';
        P_LVL = [14.0 12.0 10.0 9.0 7.5 5.0 4.0 2.0 0.0 -1.5 -3.0 -5 -6.5 -8.0 -10.0 -11.5];    % STAs TX output power at 868 MHz [dBm]
        I_LVL = [45.0 42.0 34.0 33.5 31 29 27 26 25 24 23 22.5 22 21.7 21.5 21];    % STAs TX current [mA]
        I_rx = 19;  % STAs RX current [mA]
        R_LVL = [1.2e3 4.8e3 38.4e3 50e3 100e3 500e3 1000e3];   % Rate levels [bps]
        S = [-122 -113 -110 -109 -107 -97 -97];   % Sensitivity [dBm] for each rate level
   
    case TRANSCEIVER_MODEL_SI4464
        transceiver_model_str = 'si4464 (SigFox)';
        P_LVL = [20 16 14 13 10];   % STAs TX output power at 868 MHz [dBm]
        I_LVL = [85 43 37 29 18]; % STAs TX current [mA]
        I_rx = 10.7;    % STAs RX current [mA]
        R_LVL = [500 40e3 100e3 125e3 500e3 1000e3];    % Rate levels [bps]
        S = [-126 -110 -106 -105 -97 -88];   % Sensitivity [dBm] for each rate level
   
    case TRANSCEIVER_MODEL_SX1272
        transceiver_model_str = 'SX1272/73 (LoRa)';
        P_LVL = [20 17 13 7];   % STAs TX output power at 868 MHz [dBm]
        I_LVL = [125 90 28 18]; % STAs TX current [mA]
        I_rx = 10.5;    % STAs RX current [mA]
        R_LVL = [293 586 1172 9380 18750 3750 38.4e3 250e3];    % Rate levels [bps]
        S = [-137 -134 -131 -122 -119 -116 -110 -97];   % Sensitivity [dBm] for each rate level
    
    otherwise
         error('Transceiver model unknown!');
end

GW_Ptx = P_LVL(1);  % Gateway TX output power  [dBm]. The maximum power allowed by the selected transceiver

% Topology (generate topology fixing number of rings, child ratio and max distance)
d_max = max_distance(prop_model, GW_Ptx, Grx, Gtx, S(1), f); % GW max distance (with max TX power and min TX rate)
br = 1;                             % Num of branches
n = child_ratio.^((1:num_rings)-1); % Num of nodes in each ring in each branch
n_total = sum(n) * br;              % Total num of nodes in the network

% Plot topology
if plot_topology
    
    figure
    A = zeros(n_total,n_total); % Adjacency matrix
    ring_aux = 0;
    ring_offset = 0;
    ring_old= 0;
    for i = 1:n_total
        % Get ring
        for k = 1:num_rings
            if i <= sum(n(1:k))
                ring_aux = k;
                if ring_aux ~= ring_old
                    ring_offset  = 0;
                    ring_old = ring_aux;
                end
                break
            end
        end
        if(ring_aux<num_rings)
            for j = 1:child_ratio
                A(i,i+(j-1)+child_ratio^(ring_aux-1)+ring_offset) = 1;
                A(i+(j-1)+child_ratio^(ring_aux-1)+ring_offset,i) = 1;
            end
            ring_offset = ring_offset + (child_ratio-1);
        else
            break
        end
    end

    G = graph(A);
    plot(G, 'black')
    title('Branch topology')
    axis off
    dim = [.8 .55 .3 .3];
    str = ['# of rings: ' num2str(num_rings)];
    annotation('textbox',dim,'String',str,'FitBoxToText','on');
    dim = [.8 .45 .3 .3];
    str = ['child ratio: ' num2str(child_ratio)];
    annotation('textbox',dim,'String',str,'FitBoxToText','on');

end

switch spread_model
    case RING_SPREAD_MODEL_EQUIDISTANT
        spread_model_str = 'Equidistant';
    case RING_SPREAD_MODEL_FIBONACCI
        spread_model_str = 'Fibonacci';
    case RING_SPREAD_MODEL_INVERSE_FIBONACCI
        spread_model_str = 'Inverse Fibonacci';
    otherwise
        error('Spread model unknown!');
end

d_ring = spread_rings(spread_model, fibo_stress, num_rings, d_max);   % Distance between each ring and the GW

% Plot ring spreading per each model
if plot_ring_spread
    figure
    d_ring_plot = spread_rings(0, fibo_stress, num_rings, d_max);   % Distance between each ring and the GW
    plot([0 d_ring_plot], '-*')
    hold on
    d_ring_plot = spread_rings(1, fibo_stress, num_rings, d_max);
    plot([0 d_ring_plot], '-*')
    hold on
    d_ring_plot = spread_rings(2, fibo_stress, num_rings, d_max);
    plot([0 d_ring_plot], '-*')
    hold on
    xlabel('r')
    ylabel('d [m]')
    ylim([0 d_max])
    grid on
    legend('Equidistant', 'Fibonacci', 'R-Fibonacci')
end

disp('- Distance between each ring and the GW (m):')
disp(d_ring)

% Number and set of every possible combination of ring hops
[num_delta_combinations, delta_combinations] = get_all_ring_hops(num_rings);  
disp(['- Possible delta combinations (total of ' num2str(num_delta_combinations) '):'])
disp(delta_combinations)

% Save configuration parameters as global variables to be used by other
% scripts (NOTE: mind the name repetition of variables!)
save('configuration.mat')
disp('Configuration saved!')





