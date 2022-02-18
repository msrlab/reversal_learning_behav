function [stats]= stats_behav(data, miss_ind)
% calculate diverse descriptive statistics 
% nr_corr: correct responses
% nr_err: overall errors
% nr_miss: misses
% perc_corr: percent correct trials
% perc_err: percent error trials
% are calculated across stimuli (stats.all)
% and for each stimulus (stats.stim{i})

temp = data{3};
for i= 1:length(temp)
    if data{3}(i) == 1 %%&& (data{6}(i)==1) add this part if only correct and contingent trials should count
      corr_false_vec(i)= 1; %vector with 1 for correct, 0 for false
    elseif data{3}(i) == 2 %%&& (data{6}(i)==1)
      corr_false_vec(i)= 0; 
    end;
end;

%%%% STATS TO COUNT CORRECT AND ERROR TRIALS OVER TOTAL EXPERIMENT
stats.all.nr_corr=sum(corr_false_vec);  %Anzahl korrekter Trials
stats.all.nr_err=length(data{3})-stats.all.nr_corr;  %Anzahl inkorrekter Trials
try
    stats.all.nr_miss=length(miss_ind);
catch
    stats.all.nr_miss=1;
end;
cont=data{6};  %data{1} codes contingency (1 cotingent, 0 non-contingent)
stats.all.perc_corr=stats.all.nr_corr/length(data{3}); %percent correct trials
stats.all.perc_err=stats.all.nr_err/length(data{3}); %percent error trials
stats.all.nr_trial = length(data{3});
stats.all.target = data{5};

%%%% STATS TO COUNT PERSEVERATIVE ERROR (STICK TO PREVIOUSLY CORRECT CHOICE, ALTHOUGH NEW TARGET IS  REINFORCED, see D'Cruz)
stats.all.persv_error = 0; 
i = 1;
j =1;
current_target = data{5}(i); 
stats.all.track_reversal = 0;
while i <= length(temp) 
    %%% ignore first block 
    if current_target == data{5}(i)                                                             
        stats.all.track_reversal(j) = 0;
        j = j +1;   
    else
        % set current_target
        current_target = data{5}(i);                                                     
        stats.all.track_reversal(j) = 1;
        j = j+1; 
    end;
    length(stats.all.track_reversal);
    i = i+1;
end; 

i = 1;
current_target = data{5}(i);

while i < length(temp)   
    %%% ignore first block 
    if current_target == data{5}(i)                                                                                                                     
        i = i +1;   
    else 
        % set current_target
        current_target = data{5}(i);
        while corr_false_vec(i) == 0 && i <= length(temp) && current_target < 3             
                stats.all.persv_error = stats.all.persv_error + 1;                         
                if i < length(temp)                                                                                                     
                    i = i+1;    
                else 
                %%% to exit loop
                current_target = 99;                                                                        
                end;                         
        end;
    end;    
end;

%%%% STATS TO COUNT REGRESSIVE ERROR (CHOOSE AGAIN PREVIOUSLY CORRECT CHOICE EVEN THOUGH NEW CORRECT TARGET WAS SELECTED AT LEAST ONCE, see D'Cruz)
stats.all.regr_error = 0;

i = 1;
criteria = 0;
current_target = data{5}(i); 

while i < length(temp)                                                                     
    if current_target == data{5}(i)                                                            
        i = i +1;   
    else
        current_target = data{5}(i);                                                        
        while current_target == data{5}(i)  && i <= length(temp)                                
            if corr_false_vec(i) == 0 && criteria == 1                                     
                stats.all.regr_error = stats.all.regr_error +1;        
            elseif corr_false_vec(i) == 1
                criteria = 1; 
            end; 
            if i < length(temp)
            i = i+1;
            else 
                current_target = 99;
            end;
        end;        
        %current_target = data{5}(i);
        criteria = 0;
    end;
end;


%%%%% STATS TO DIVIDE CORRECT AND ERROR TRIALS PER REVERSAL BLOCK
k = 1; 
j = 1;
corr = 0;
error = 0;
current_target = data{5}(j);   
for j = 1:length(data{3})
      if j == length(data{3})
         if corr_false_vec(j)==1
         corr = corr + 1;
         stats.block_corr{k} = corr;
         stats.block_error{k} = error;
         else
         error = error + 1;
         stats.block_error{k} = error;
         end;
      elseif data{5}(j) == current_target; %%% trial number
         if corr_false_vec(j)==1
         corr = corr + 1;
         else
         error = error + 1;
         end;
      else
         stats.block_corr{k} = corr;
         stats.block_error{k} = error;
         current_target = data{5}(j);
         k = k + 1;
         if corr_false_vec(j)==1
            corr = 1;
            error = 0;
         else
            error = 1;
            corr = 0;
         end;
      end;
end;


%%%fill array so length is always 13 to avoid strange formatting of text
%%%file
if length(stats.block_corr)<13
    for j = length(stats.block_corr)+1 : 13
        stats.block_corr{j} = 999;
        stats.block_error{j} = 999;
        stats.block_trialno{j} = 999;
        stats.block_criteria{j} = 999;
    end; 
end; 

