function [ actions_history ] = ... 
        learn_optimal_routing( max_num_iterations, set_of_ring_hops_combinations, aggregation_on, learning_approach, d_ring )
    %LEARN_OPTIMAL_ROUTING applies learning for identfying an optimal (or
    %pseudo-optimal) ring hops combination
    %   Detailed explanation goes here
    
    % At the moment just consider e-greedy learning approach
    
%     switch learning_approach
%         
%         case 0
% 
%         otherwise
%             error('Learning approach unkown!')
%     
%     end

    load('configuration.mat')

    % Learning tunning parameters
    epsilon_initial = 0.2;

    num_possible_arms = size(set_of_ring_hops_combinations, 1);
    
    disp(['- num_possible_arms ' num2str(num_possible_arms)])

    reward_per_arm = ones(1,num_possible_arms) .* -1;
    
    actions_history = zeros(max_num_iterations, 3);

    iteration = 1;

    epsilon = epsilon_initial;
    
    disp('  � progress: 0%')
    while(iteration <= max_num_iterations) 
        
        % disp(['- iteration ' num2str(iteration)])

        % Pick a ring hops combination (i.e., arm)
        selected_arm = select_action_greedy(reward_per_arm, epsilon);
        
        ring_hops_combination = set_of_ring_hops_combinations(selected_arm,:);
                
        [btle_e, btle_ix, ~, ~, ~] = general_optimal_tx_conf(ring_hops_combination, aggregation_on, d_ring);
        
        % disp(['  � selected_arm: ' num2str(selected_arm) ' (' num2str(btle_e) ' mJ)'])

        reward = 1/btle_e;
        reward_per_arm(selected_arm) = reward;      

        actions_history(iteration, :) = [selected_arm btle_e btle_ix];
        
        % epsilon = epsilon_initial / sqrt(iteration);    
        epsilon = epsilon_initial;
        
        % Increase the number of 'learning iterations' of a WLAN
        iteration = iteration + 1; 
        
        if(iteration == max_num_iterations)
        disp('  � progress: 100 %')
        else
        disp(['  � progress: ' num2str(ceil(iteration*100 / max_num_iterations)) '%'])
        end
        
    end
    
end
