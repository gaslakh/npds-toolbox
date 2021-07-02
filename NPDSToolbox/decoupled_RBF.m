%%% THE RADIAL BASIS FUNCTION METHOD  FOR SOLVING THE DE-COUPLED MODEL FOR A POPULATION OF NEURONS WITHOUT WHITE NOISE
% NPDSToolbox version 1.0.0
% handles    Structure with handles and user data (see GUIDATA)
% M          Number of time steps
% flag		 (On/Off) Showing plots

%---- Outputs -----
% phi 		  Current distibution
% L2		  The error calculated between the current distribution and the final distribution in the past time steps
% thetas      Phase position of the population of uncoupled neurons
% u			  Vlaue of control function
% sim_time    Descrete simulation time
% domain	  Spatial domain points (between 0 and 2*pi)

% For more information about the numerical approach, see the package
% documentaion
% Link : www.CMPLAB.com

function [phi,L2,thetas,u,sim_time,domain]=decoupled_RBF(handles,M,flag)
contents = get(handles.popupm_Init_Dist,'String');
val = contents{get(handles.popupm_Init_Dist,'Value')};
contents = get(handles.popup_Final_Dist,'String');
val2 = contents{get(handles.popup_Final_Dist,'Value')};

contents = get(handles.Popup_PRC,'String');
model = contents{get(handles.Popup_PRC,'Value')};

population=str2double(get(handles.Edit_Pop,'string'));
T=str2double(get(handles.Edit_Oscillator_Period,'string'));
duration=str2double(get(handles.Edit_FinalT,'string'));

omega=(2*pi)/T;
dt=T/M;
S=duration*M;

N=150;
domain=linspace(0,2*pi,N);

%PRC function and its derivative
[Z,Zp]=PRC_function(model,'RBF',domain);


load('Matrices\RBFmatrix.mat');


%Initial condition
phi(1,:)=dist_def(val,str2num(get(handles.Edit_Mean_Initial_Dist,'string')),str2num(get(handles.Edit_Varience_Initial_Dist,'string')),omega,0,dt,domain);
peak1=max(phi(1,:));


%Desired distribution
phif(1,:)=dist_def(val2,str2num(get(handles.Edit_Mean_Final_Dist,'string')),str2num(get(handles.Edit_Varience_Fianl_Dist,'string')),omega,0,dt,domain);
peak2=max(phif(1,:));
peak=max(peak1,peak2);

thetas=zeros(S,population);
th=linspace(0,2*pi,1000);
thetas(1,:)=(init_tetha(population,phi(1,:),N,domain))';

%Control inputs
u=zeros(S+1,1);
sim_time=linspace(0,duration*T,S+1);

%Process type report
report_main(handles,str2num(get(handles.Edit_Mean_Initial_Dist,'string')),str2num(get(handles.Edit_Varience_Initial_Dist,'string')),omega,0,dt,domain);

%L_2 norms
L2=zeros(S+1,1);
L2(1)=trapz(domain,(phi(1,:)-phif(1,:)).^2);
for i=1:S
    A1=RBF+dt*(omega*DRBF+u(i)*diag(Zp')*RBF+u(i)*diag(Z')*DRBF);
    B1=phi(i,:);
    A2=RBF(1,:)-RBF(N,:);
    B2=0;
    A=[A1;A2];
    B=[B1,B2];
    weight=A\B';
    phi(i+1,:)=RBF*weight(1:N);
    phif(i+1,:)=dist_def(val2,str2num(get(handles.Edit_Mean_Final_Dist,'string')),str2num(get(handles.Edit_Varience_Fianl_Dist,'string')),omega,i,dt,domain);
    L2(i+1)=trapz(domain,(phi(i+1,:)-phif(i+1,:)).^2);
    u(i+1)=control_input(handles,domain,Z,Zp,L2,omega,i,dt,phi(i,:),phif(i,:));
    thetas(i+1,:)=RK4control(thetas(i,:),u(i+1),T,dt,model,'RBF');
    
    if(flag)
        Output_plots(handles,peak,duration*T,domain,phi(i,:),phif(i,:),sim_time(1:i),u(1:i),L2(1:i),cos(thetas(i,:)),sin(thetas(i,:)),cos(th),sin(th));
        
        
        if abs(trapz(domain,phi(i,:))-1)>2
            errordlg('Method is unstable','Unstablity Error');
            break;
        end
        
        if ~get(handles.Start_button, 'userdata') % stop condition
            break;
        end
        
        if get(handles.Pause_button, 'userdata') % stop condition
            while get(handles.Pause_button, 'userdata')
                pause(0.1)
            end
        end
    end
end
report_last(handles.Text_result,sim_time,u',L2,thetas,phi,i)