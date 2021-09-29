%% reset + hello
close all; clc; clear all;

linewidth = 2;

warning off
addpath('./functions/')
excel=xlsread('./Input.xlsx');

c_Grid_size = 100;

cL=excel(3,1); cH = excel(3,10);
c=linspace(cL,cH,c_Grid_size);

f=excel(1,1:10);
f=interp1(excel(3,1:10),f,c);
f=f./sum(f);
F=cumsum(f);
v=interp1(excel(3,1:10),excel(2,15:24),c);
S=round(excel(end,15),0);

cL = c(1); cH = c(end);

if excel(2,15)-excel(3,15)<0 %ends program if the first v is smaller than the first entry in the cost grid
    box=msgbox('Program ended.Please ensure your first  v is greater than the first entry in the cost grid.');
    fprintf('\n Program ended.Please ensure your first  v is greater than the first entry in the cost grid. \n')
    return
end


%% Step 1: Plot w
fprintf('1a. Calculating Virtual Valuation (w) (In progress...)\n')
w = nan(1,length(c));
w(1)=v(1)-c(1);
for i=2:length(c)
    w(i)=v(i)-c(i)-(c(i)-c(i-1))*F(i-1)/f(i);
end

figure
x0=50;
y0=50;
width=2*550;
height=2*400;
set(gcf,'position',[x0,y0,width,height])
plot(c,w,'linewidth',linewidth)
xlabel('Cost $c$','interpreter','latex')
title('Virtual Valuation ($w=v-c-\Delta c \cdot F/f$)','interpreter','latex')

fprintf('1b. Calculating Virtual Valuation (w) (Done.)\n')

if max(w)<=0 %ends the program if the virtual valuation function has a maximum of less than or equal to 0.
    fprintf('The Virtual Valuation function is always negative or zero. Thus, for your inserted parameters, there are  no gains to be realized from holding this auction.');
    box2=msgbox('The Virtual Valuation function is always negative or zero. Thus, for your inserted parameters, there are  no gains to be realized from holding this auction.');
    return
end

dlgTitle    = 'User Question';
dlgQuestion = 'Is the virtual valuation single-peaked? If yes, continue. If no, please revise your input.';
choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
close all
if strcmp(choice,'No')
    fprintf('\n Program ended by user.\n')
    return
end


if min(w)<0 && max(w)>0
    
    c0=cH;
    cLastPos=cH;
    cLastPos_iter=c_Grid_size;
    for iter=1:length(w)-1
        if w(iter)>0 && w(iter+1)<0
            c0=c(iter+1);
            cLastPos=c(iter);
            cLastPos_iter=iter;
        end
    end
    
    %finding the equation of the hypothetical interpolated line, given
    %points in the (c, w) plane: (cLastPos, w(cLastPos_Iter)) and (c0,
    %w(cLastPos_iter + 1))
    
    w1=w(cLastPos_iter);
    w2=w(cLastPos_iter+1);
    c1=cLastPos;
    c2=c0; %these are the points
    
    interp_m=(w2-w1)/(c2-c1);
    interp_q=w1-interp_m*c1; %slope and y-intercept
    
    interp_cint=-interp_q/interp_m; %x-intercept
    cZero=interp_cint;
    fval=0;
    
    %I tried lots of extreme cases and this failsafe never triggered. The
    %only way it would trigger is if c2=c1, and I don't see a reason why
    %that'd occur (c is genererated by a linspace command and the c0 and
    %cLastPos variables are necessarily unique if there's a sign change.
    %It's here "just in case", but it can probably be safely removed.
    
    if isnan(cZero) || isinf(cZero) || cLastPos > cZero || c0 < cZero %cZero cannot be NaN, infinity, or outside the interval [cLastPos, c0]
        [cZero,fval]=fzero(@(x) interp1(c,w,x),[cLastPos, c0]); %sometimes something dumb happens and an NaN error occurs. This manually restricts the search space for fzero to the relevant range and should guarantee the proper zero is found
        
        if isnan(cZero) || isinf(cZero) || cLastPos > cZero || c0 < cZero %then if for some reason the manual restriction fails (it shouldn't), we just set it to last positive
            cZero=cLastPos;
        end
    end
    
    
    figure
    x0=50;
    y0=50;
    width=2*550;
    height=2*400;
    set(gcf,'position',[x0,y0,width,height])
    hold on
    plot(c,w,'linewidth',linewidth)
    scatter(cZero,fval,'MarkerFaceColor','Magenta','MarkerEdgeColor','Magenta')
    text(cZero,fval,'Reserve Price','VerticalAlignment','top','HorizontalAlignment','right');
    xlabel('Cost $c$','interpreter','latex')
    title('Virtual Valuation ($w=v-c-\Delta c \cdot F/f$)','interpreter','latex')
    
    dlgTitle    = 'User Question';
    dlgQuestion = ['I detected the virtual valuation has a zero-cross. The reserve price is: ' num2str(round(cZero,4)) '. Do you wish to continue?'];
    choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
    close all
    if strcmp(choice,'No')
        fprintf('\n Program ended by user.\n')
        return
    end
    
end

%% Step 2
fprintf('2a. Calculating Optimal Lola (In progress...)\n')

progressbar = waitbar(0,'1','Name','Approximating pi...',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');

setappdata(progressbar,'canceling',0);

for pL_iter=1:c_Grid_size
    
    % Check for clicked Cancel button
    if getappdata(progressbar,'canceling')
        break
    end
    
    %% Q Lola: (1-(1-F(p)).^S)./(N*F(p)).*(c<p) + (1-F(c)).^(S-1).*(p<c);
    Q_theory_p = 0;
    for j = 0 : S-1
        Q_theory_p = Q_theory_p ...
            + (1/(j+1))*nchoosek(S-1,j) *F(pL_iter)^j * (1-F(pL_iter))^(S-1-j);
    end
    Q_theoryLOLA = zeros(c_Grid_size,1);
    Q_theoryLOLA(1 : pL_iter) = Q_theory_p;
    c_end=c_Grid_size;
    if min(w)<0 && max(w)>0
        c_end=cLastPos_iter;
    end
    for t = pL_iter + 1 : c_end
        for j = 0 : S-1
            Q_theoryLOLA(t) = Q_theoryLOLA(t) ...
                + (1/(j+1))*nchoosek(S-1,j) *f(t)^j * (1-F(t))^(S-1-j);
        end
    end
    
    %% Q FPA
    Q_theoryFPA=zeros(c_Grid_size,1);
    for t =1 : c_end
        for j = 0 : S-1
            Q_theoryFPA(t) = Q_theoryFPA(t) ...
                + (1/(j+1))*nchoosek(S-1,j) *f(t)^j * (1-F(t))^(S-1-j);
        end
    end
    
    %% Final Output
    BS_FPA(pL_iter)=(w.*f)*Q_theoryFPA;
    BS_Lola(pL_iter)=(w.*f)*Q_theoryLOLA;
    
    SS_FPA(pL_iter)=((v-c).*f)*Q_theoryFPA;
    SS_Lola(pL_iter)=((v-c).*f)*Q_theoryLOLA;
    
    Pi_FPA(pL_iter)=SS_FPA(pL_iter)-BS_FPA(pL_iter);
    Pi_Lola(pL_iter)=SS_Lola(pL_iter)-BS_Lola(pL_iter);
    
    % Update waitbar and message
    waitbar(pL_iter/c_Grid_size,progressbar,sprintf('Completed: %12.0f%%',100*pL_iter/c_Grid_size))
    
end
delete(progressbar)
[valBS,indexBS]=max(BS_Lola);
fprintf('Floor Price that max Buyer Surplus is: %12.4f\n',c(indexBS))
[valSS,indexSS]=max(SS_Lola);
fprintf('Floor Price that max Social Surplus is: %12.4f\n',c(indexSS))
fprintf('2b. Calculating Optimal Lola (Done.)\n')

%%
figure
x0=50;
y0=50;
width=2*550;
height=2*400;
set(gcf,'position',[x0,y0,width,height])
subplot(2,2,1)
hold on
plot(c,BS_Lola,'linewidth',linewidth)
scatter(c(indexBS),BS_Lola(indexBS),'MarkerFaceColor','red','MarkerEdgeColor','red')
text(c(indexBS),BS_Lola(indexBS),'Floor Price','VerticalAlignment','top','HorizontalAlignment','right');
if min(w)<0 && max(w)>0
    scatter(cZero,interp1(c,BS_Lola,cZero),'MarkerFaceColor','Magenta','MarkerEdgeColor','Magenta')
    text(cZero,interp1(c,BS_Lola,cZero),'Reserve Price','VerticalAlignment','top','HorizontalAlignment','right');
end
xlabel('Floor Price $p_L$','interpreter','latex')
title('Lola Buyer Surplus','interpreter','latex')

subplot(2,2,2)
hold on
temp=100*(BS_Lola./BS_FPA-1);
plot(c,temp,'linewidth',linewidth)
scatter(c(indexBS),temp(indexBS),'MarkerFaceColor','red','MarkerEdgeColor','red')
text(c(indexBS),temp(indexBS),'Floor Price','VerticalAlignment','top','HorizontalAlignment','right');
if min(w)<0 && max(w)>0
    scatter(cZero,interp1(c,temp,cZero),'MarkerFaceColor','Magenta','MarkerEdgeColor','Magenta')
    text(cZero,interp1(c,temp,cZero),'Reserve Price','VerticalAlignment','top','HorizontalAlignment','right');
end
xlabel('Floor Price $p_L$','interpreter','latex')
title('Lola Buyer Surplus [\% improvement over FPA]','interpreter','latex')

%%
subplot(2,2,3)
hold on
plot(c,SS_Lola,'linewidth',linewidth)
scatter(c(indexSS),SS_Lola(indexSS),'MarkerFaceColor','red','MarkerEdgeColor','red')
text(c(indexSS),SS_Lola(indexSS),'Floor Price','VerticalAlignment','top','HorizontalAlignment','right');
if min(w)<0 && max(w)>0
    scatter(cZero,interp1(c,SS_Lola,cZero),'MarkerFaceColor','Magenta','MarkerEdgeColor','Magenta')
    text(cZero,interp1(c,SS_Lola,cZero),'Reserve Price','VerticalAlignment','top','HorizontalAlignment','right');
end
xlabel('Floor Price $p_L$','interpreter','latex')
title('Lola Social Surplus','interpreter','latex')

subplot(2,2,4)
hold on
temp=100*(SS_Lola./SS_FPA-1);
plot(c,temp,'linewidth',linewidth)
scatter(c(indexSS),temp(indexSS),'MarkerFaceColor','red','MarkerEdgeColor','red')
text(c(indexSS),temp(indexSS),'Floor Price','VerticalAlignment','top','HorizontalAlignment','right');
if min(w)<0 && max(w)>0
    scatter(cZero,interp1(c,temp,cZero),'MarkerFaceColor','Magenta','MarkerEdgeColor','Magenta')
    text(cZero,interp1(c,temp,cZero),'Reserve Price','VerticalAlignment','top','HorizontalAlignment','right');
end
xlabel('Floor Price $p_L$','interpreter','latex')
title('Lola Social Surplus [\% improvement over FPA]','interpreter','latex')

dlgTitle    = 'Output';
dlgQuestion = ['Lola Optimal Floor Prices (Red Dots) are: (i.) for buyer surplus ' num2str(round(c(indexBS),2)) ' and (ii.) for social surplus ' num2str(round(c(indexSS),2)) '.'];

dlgQuestion2='';
if min(w)<0 && max(w)>0
    dlgQuestion2 = ['The Optimal Reserve Price (Magenta Dots) is: ' num2str(round(cZero,2)) '.'];
end
choice = questdlg([dlgQuestion dlgQuestion2 "Do you want to close the program?"],dlgTitle,'Yes','No', 'Yes');
close all