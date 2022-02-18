function sh = run_analysis
%This script was used to perform the modelling analysis for the paper 
%"Developmental Differences in Probabilistic Reversal Learning: a 
%Computational Modeling Approach" by Eileen Weiss, Jana A Kruppa, Gereon R
%Fink, Beate Herpertz-Dahlmann, Kerstin Konrad and Martin Schulte-R???ther
%submitted for consideration of publication to "Frontiers in Human
%Neuroscience"
%script written by Eileen Oberwelland Weiss and Martin Schulte-Ruether
%https://github.com/msrlab/reversal-learning_behav
%
%licensed under CC-BY 4.0, https://creativecommons.org/licenses/by/4.0/

%%use the following settings for tapas
% tapas_rw_binary_config.m: RW-model
% tapas_hgf_binary_config_custom.m: HGF-model including theta
% tapas_hgf_binary_config_custom_ft.m: HGF-model including theta, but set to 0

%%% settings
% need to be changed depending on your local installation
% main path containing script and folders
sh.studypath = '/Users/admin/Documents/Aachen/NeuroSkills/analysis_openaccess/reversal-learning_behav-master';
addpath(sh.studypath);
%directory containing the data, available for download here: https://osf.io/3xrn2/
sh.logdir = fullfile(sh.studypath,'data');   
%set path for tapas
addpath(fullfile(sh.studypath,'tapas_old','HGF'))

%optional
sh.plottapas = 1;  % set to 1 if you want to plot tapas graphics during analyses for each subject
sh.printtapas = 1; % set to 1 if you want tapas graphics printed to a ps file for each subject

%read participant info
sh.infoxls=[sh.studypath filesep 'study_info_behav.xls'];
dat=importxls(sh.infoxls);
% only subjects with "1" in analyze column are further processed
subjtemp=dat.code(dat.analyze==1); 
sh.subj.code=cellstr(num2str(subjtemp))';
sh.code=cellstr(num2str(subjtemp))';
sh.group=dat.age_group(dat.analyze==1)';
sh.condition1=cellstr(dat.condition1(dat.analyze==1))';
sh.condition2=cellstr(dat.condition2(dat.analyze==1))';
sh.conditions = {'SB','IB','CB'}; 

% do it for all participants
for i = 1:length(sh.subj.code)
    %load data
    sh = load_data(sh,i)
    % calculate error rates etc.
    sh = get_stats(sh,i);
    % modelling with tapas
    sh = model_data(sh,i);
    % extract model parameters and save to file
    sh = extract_parameters(sh,i);
end
save('sh','sh');

function sh = model_data(sh,i)
% function uses tapas toolbox to fit three models (Rescorla Wagner,
% HGF-model including meta-volatiliy parameter theta, and HGF-model with
% theta set to a fixed value. see the custom tapas config files for settings used 
% tapas_rw_binary_config.m: RW-model
% tapas_hgf_binary_custom.m: HGF-model including theta
% tapas_hgf_binary_custom_ft.m: HGF-model including theta, but set to a
% fixed value
    close all
    for j=1:length(sh.conditions)
        fprintf(1,[datestr(now) '::  model_RW for ' sh.subj.code{i} ' sess ' sh.conditions{j}]);
        % get the data for the respective condition
        [data, miss_ind] = choose_data(sh,i,sh.conditions{j})
        cont_input = data{1}';
        choice_input = data{2}';
        %estimate HGF model and plot
        bopars_rw = tapas_fitModel(choice_input, cont_input, 'tapas_rw_binary_config_custom', 'tapas_softmax_binary_config','tapas_quasinewton_optim_config'); 
        plot_traj('model_rw',[sh.subj.code{i} sh.conditions{j}],bopars_rw); 
        %estimate HGF model and plot
        bopars_hgf = tapas_fitModel(choice_input, cont_input,'tapas_hgf_binary_config_custom', 'tapas_softmax_binary_config','tapas_quasinewton_optim_config');
        plot_traj('model_hgf',[sh.subj.code{i} sh.conditions{j}],bopars_hgf); 
        %estimate HGF model with fixed theta and plot
        bopars_hgfft = tapas_fitModel(choice_input, cont_input,'tapas_hgf_binary_config_custom_ft', 'tapas_softmax_binary_config','tapas_quasinewton_optim_config');
        plot_traj('model_hgfft',[sh.subj.code{i} sh.conditions{j}],bopars_hgfft); 
        %save model parameters to sh structure for later reference
        sh.bopars_rw{i}.(sh.conditions{j}) = bopars_rw
        sh.bopars_hgf{i}.(sh.conditions{j}) = bopars_hgf  
        sh.bopars_hgfft{i}.(sh.conditions{j}) = bopars_hgfft
    end
    
    function plot_traj(model,legend_str,bopars)
    % plots and prints trajectories (optional) using tapas functions
        if sh.plottapas == 1
            if strcmp(model,'model_rw')
                tapas_rw_binary_plotTraj(bopars);
            end
            if strcmp(model,'model_hgf') || strcmp(model,'model_hgfft')
                tapas_hgf_binary_plotTraj(bopars);
            end           
            fig = gcf;
            orient(fig,'landscape');
            legend(legend_str);
        end;
        cd(sh.studypath)
        if sh.printtapas == 1
            print(fig,'-dpsc2','-append',model);
        end;
    end
end

function sh = extract_parameters(sh,i) 
% writes a text file containing model parameters for each condition and
% participant
    if ~ exist([sh.studypath filesep 'model_params_try.txt'],'file')
        paramfid = fopen([sh.studypath filesep 'model_params_try.txt'],'a');
        fprintf(paramfid,'date\tsubject\tage_group\tcondition\tLME_rw\tbe_rw\tal_rw\tLME_hgf\tbe_hgf\tom_hgf\tth_hgf\tLME_hgfft\tbe_hgfft\tom_hgfft\tth_hgfft'); 
    else
        paramfid = fopen([sh.studypath filesep 'model_params_try.txt'],'a');
    end;
    
     

    
    for j=1:length(sh.conditions);
        LME_rw = sh.bopars_rw{i}.(sh.conditions{j}).optim.LME;
        LME_hgf = sh.bopars_hgf{i}.(sh.conditions{j}).optim.LME;
        LME_hgfft = sh.bopars_hgfft{i}.(sh.conditions{j}).optim.LME;
        be_rw = sh.bopars_rw{i}.(sh.conditions{j}).p_obs.be %beta
        al_rw = sh.bopars_rw{i}.(sh.conditions{j}).p_prc.al %alpha
        be_hgf = sh.bopars_hgf{i}.(sh.conditions{j}).p_obs.be; %beta
        om_hgf = sh.bopars_hgf{i}.(sh.conditions{j}).p_prc.om(2); %omega
        om_hgf = log(om_hgf);
        th_hgf = sh.bopars_hgf{i}.(sh.conditions{j}).p_prc.om(3); %theta
      
        be_hgfft = sh.bopars_hgfft{i}.(sh.conditions{j}).p_obs.be; %beta
        om_hgfft = sh.bopars_hgfft{i}.(sh.conditions{j}).p_prc.om(2); %omega
        om_hgfft = log(om_hgfft);
        th_hgfft = sh.bopars_hgfft{i}.(sh.conditions{j}).p_prc.om(3); %theta
        subject= sh.subj.code{i};           %%%current subject name (200, 201...)                         
        code=sh.subj.code{i};              %%%current subject code 
        condition= sh.conditions{j};    %%% currrent condition (SB; CB; IB)
        age_group= sh.group(i);
        fprintf(paramfid,'\n%s\t%s\t%i\t%s\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f',datestr(now,0),subject, age_group, condition, LME_rw, be_rw, al_rw, LME_hgf, be_hgf, om_hgf, th_hgf, LME_hgfft, be_hgfft, om_hgfft, th_hgfft);
    end
    fclose(paramfid);
end

function sh = get_stats(sh,i)
% writes a text file with standard descriptive statistics for each
% condition and participant
    if ~ exist([sh.studypath filesep 'descr_statistics.txt'],'file')
        statsfid = fopen([sh.studypath filesep 'descr_statistics.txt'],'a');
        fprintf(statsfid,'date\tsubject\tage_group\tcondition\tnr_trial\tnr_correct\tnr_err\tnr_miss\tperc_corr\tperc_err\tnr_persv_error\tnr_regr_error\tnr_reversal'); 
    else
        statsfid = fopen([sh.studypath filesep 'descr_statistics.txt'],'a');
    end;

    for j=1:length(sh.conditions);
        [data, miss_ind] = choose_data(sh,i,sh.conditions{j})
        fprintf(1,[datestr(now) '::  calculating statistics for behavioral data subject ' sh.subj.code{i} ' sess ' sh.conditions{j} ': ' ]);
        stats = stats_behav(data,miss_ind);         %%%sub function that does the actual statistics (stats_behav.m)
        %%% next part sorts the results from stats_behav in
        %%% variables that will be written to the text file 
        nr_corr= stats.all.nr_corr;                 %%% total number of correct trials 
        nr_err=stats.all.nr_err;                    %%% total number of errors
        nr_miss=stats.all.nr_miss;                  %%% total number of misses
        perc_corr=stats.all.perc_corr;              %%% percentage of total correct trials (thus relative to the number of total trials)
        perc_err=stats.all.perc_err;                %%% percentage of total error trials (thus relative to the number of total trials)
        nr_trial_all = stats.all.nr_trial;          %%% total number of trials 
        nr_persv_error = stats.all.persv_error;     %%% total number of perseveraritve errors (see D'Cruz et al.)
        nr_regr_error = stats.all.regr_error;       %%% total number of regressive errors (see D'Cruz)
        reversals = sum(stats.all.track_reversal);       %%% total number of reversals 
        targets = stats.all.target;      
        %%% Numbers of whatever PER REVERSAL BLOCK
        nr_corr_block = cell2mat(stats.block_corr);         %%number of correct trials per reversal block, will be written to text file for each reversal block separately
        nr_error_block = cell2mat(stats.block_error);       %%number of error trials per reversal block, will be written to text file for each reversal block separately
        subject= sh.subj.code{i};           %%%current subject name (200, 201...)                         
        code=sh.subj.code{i};              %%%current subject code 
        condition= sh.conditions{j};    %%% currrent condition (SB; CB; IB) 
        age_group= sh.group(i); 
        fprintf(statsfid,'\n%s\t%s\t%i',datestr(now,0),subject, age_group);
        fprintf(statsfid,'\t%s\t%4i\t%4i', condition,nr_trial_all,nr_corr);
        fprintf(statsfid,'\t%4i\t%4i\t%4f', nr_err,nr_miss,perc_corr);
        fprintf(statsfid,'\t%4f\t%4i\t%4i\t%4i', perc_err,nr_persv_error, nr_regr_error,reversals);

    end
    
    fclose(statsfid);
end

function sh = load_data(sh,i)
% loads mat files which contain the data
% data should be a 1 x 6 cell, containing trial-by-trial trajectories (missings already
% removed)
% data{1} = cont_input;  % "inputs" in contingency space, as needed for tapas
% toolbox, i.e. stim1 + reward --> 1; stim2 + noreward --> 1
%               stim2 + reward --> 0; stim1 + noreward --> 0
% data{2} = choice_response; % "responses" in contingency space, as needed
% for tapas, i.e. correct response when target 1 is correct--> 1;
%                 correct response when target 2 is correct--> 0;
%                 incorrect response when target 1 is correct--> 0;
%                 incorrect response when target 2 is correct--> 1;
% see tapas manual for further information
% data{3}: response;     % correct (1) or incorrect (2)
% data{4}: feedback;    % positive (1) or neutral (2)
% data{5}: target;    % which stimulus is the current target (1) or (2)
% data{6}: contingency;     % contingent feedback 
%          positive after correct, neutral after incorrect --> 1 
%          neutral after correct, positive after incorrect --> 0
% miss_ind: index of trials which have been removed because they were 
% misses
    sh.datfile_s{i}=[sh.logdir filesep sh.subj.code{i} '_SB.mat'];              
    sh.datfile_i{i}=[sh.logdir filesep sh.subj.code{i} '_IB.mat'];
    sh.datfile_c{i}=[sh.logdir filesep sh.subj.code{i} '_CB.mat'];
    sh.data_s{i} = load(sh.datfile_s{i})
    sh.data_i{i} = load(sh.datfile_i{i})
    sh.data_c{i} = load(sh.datfile_c{i})
end

function [data, miss_ind] = choose_data(sh,i,cond)
% helper function to select the correct data for respective condition
        if strcmp(cond(1),'S')
           data = sh.data_s{i}.data
           miss_ind = sh.data_s{i}.miss_ind
        end
        if strcmp(cond(1),'I');
           data = sh.data_i{i}.data
           miss_ind = sh.data_i{i}.miss_ind
        end;
        if strcmp(cond(1),'C');
           data = sh.data_c{i}.data
           miss_ind = sh.data_c{i}.miss_ind
        end;
end

function [out] = importxls(filename)
% quick and dirty import of excel tables
% prerequisites of excel table: 
%   - only first row contains variable names (strings) and no
%   numerical values
%   - no empty rows, no empty cells
%   - first and last column must be numerical
%   - columns either numerical or text
%
% first row of table are names of variables
    [out.nums out.txt]= xlsread(filename);

    for i = 1: length(out.txt(1,:))
      evalstr = ['out.' out.txt{1,i} ' =  out.nums(:,i);'];
      eval(evalstr);
      evalifstr = ['if sum(isnan(out.' out.txt{1,i} ')) == length(out.' ...
               out.txt{1,i} '); out.' out.txt{1,i} ' =  out.txt(2:length(out.txt(:,1)),i); end;' ];
      eval(evalifstr);
    end
    out=rmfield(out,'nums');
    out=rmfield(out,'txt');
end

end

