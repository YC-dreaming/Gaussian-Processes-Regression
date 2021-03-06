load Gaussian_process_regression_data.mat;
load task2actual_data.mat;
%picking optimized hyperparameters
l=0.5552;
sigma_f=0.0816;
sigma_n=-0.0481;

X_o=input_train';
Y_o=target_train;
%K calculation begins
K = zeros(size(X_o,2));
kernel_function_m = @(x,x2) sigma_f^2*exp((x-x2)'*(x-x2)/(-2*l^2));
error_function_m = @(x,x2) sigma_n^2*(sum(x==x2)==length(x));
k_m = @(x,x2) kernel_function_m(x,x2)+error_function_m(x,x2); 
for i=1:size(X_o,2)
    for j=1:size(X_o,2)
        K(i,j)=k_m(X_o(:,i),X_o(:,j));
    end
end
%K ends

prediction_x=input_test';
%K_ss calculation begins
K_ss=zeros(size(prediction_x,2));

for i=1:size(prediction_x,2)
    for j=i:size(prediction_x,2)
        K_ss(i,j)=k_m(prediction_x(:,i),prediction_x(:,j));
    end
end
%optimisation exploiting the diagonal symmetry of K_ss
K_ss=K_ss+triu(K_ss,1)';
%K_ss ends
%K_S calculation begins
K_s=zeros(size(prediction_x,2),size(X_o,2));

for i=1:size(prediction_x,2)
    for j=1:size(X_o,2)
        K_s(i,j)=k_m(prediction_x(:,i),X_o(:,j)); 
    end
end
%K_s ends
%calculate Mu and Sigma
%use cholesky decomposition
L=chol(K,'lower');
alpha=L'\(L\Y_o);
disp('Our predicted data(mean)');
Mu = K_s*alpha;
disp(Mu);
v=L\K_s';
Sigma = 1.96*sqrt(diag(K_ss-v'*v));
upper_confidence=Mu+Sigma;
lower_confidence=Mu-Sigma;
target_predicted=Mu;
save('task2output.mat','target_predicted');
figure
plot_variance = @(x,lower,upper,color) set(fill([x,x(end:-1:1)],[upper,fliplr(lower)],color),'EdgeColor',color);
plot_variance([1:size(target_test,1)],(lower_confidence)',(upper_confidence)',[0.8 0.8 0.8])
hold on
set(plot(Mu,'k-'),'LineWidth',1)
set(plot(target_test,'r.'),'MarkerSize',8)
%Calculating how many actual data points do not lie in our confidence
%interval
count_outliers=0;
for i=1:size(target_test,1)
    if target_test(i)>upper_confidence(i) || target_test(i)<lower_confidence(i)
        count_outliers=count_outliers+1;
    end
end
title (['Number of points which lie outside the confidence interval=' num2str(count_outliers) ' of ' num2str(size(target_test,1))])
legend('confidence bounds','prediction(mean)','actual data points','location','SouthEast')
