function results = simulate_vref_error()
%SIMULATE_VREF_ERROR 基准电压偏差对测量结果的影响仿真
%   验证结论1：基准电压的稳定性显著影响双积分式电压表的测量精度，
%   且稳定性越高双积分式电压表的测量精度越高
%
%   输出:
%       results: 包含仿真结果的表格

    % 仿真参数设置
    V_in = 2.5;  % 固定输入电压 2.5V
    V_ref_nominal = 5.0;  % 标称基准电压 5V
    T1 = 0.1;  % 积分时间 100ms
    f_clk = 1e6;  % 时钟频率 1MHz
    
    % V_ref偏差范围：±1%
    V_ref_deviation_percent = (-1:0.05:1)';  % 偏差百分比
    V_ref_values = V_ref_nominal * (1 + V_ref_deviation_percent / 100);
    
    % 初始化结果数组
    n_points = length(V_ref_values);
    errors = zeros(n_points, 1);
    relative_errors = zeros(n_points, 1);
    V_measured_values = zeros(n_points, 1);
    
    % 理想条件（无其他非理想因素）
    V_offset = 0;
    V_bias = 0;
    R_leak = inf;
    C = 1e-6;
    R = 100e3;
    noise_signal = @(t) 0;
    
    % 对每个V_ref值进行仿真
    fprintf('正在进行基准电压偏差仿真...\n');
    for i = 1:n_points
        V_ref = V_ref_values(i);
        [T2, ~, ~, ~] = dual_slope_dvm(V_in, V_ref, T1, f_clk, ...
            V_offset, V_bias, R_leak, C, R, noise_signal);

        % 以标称V_ref进行换算，模拟未校准状态下的参考电压偏差影响
        V_measured = V_ref_nominal * (T2 / T1);
        error = V_measured - V_in;
        
        errors(i) = error;
        relative_errors(i) = abs(error / V_in) * 100;  % 相对误差百分比
        V_measured_values(i) = V_measured;
        
        if mod(i, 10) == 0
            fprintf('  进度: %d/%d\n', i, n_points);
        end
    end
    
    % 创建结果表格
    results = table(V_ref_deviation_percent, V_ref_values, V_measured_values, ...
        errors, relative_errors, ...
        'VariableNames', {'V_ref_Deviation_Percent', 'V_ref_Value_V', ...
        'V_measured_V', 'Error_V', 'Relative_Error_Percent'});
    
    % 保存表格到Excel
    writetable(results, 'results_vref_error.xlsx');
    fprintf('结果已保存到 results_vref_error.xlsx\n');
    
    % 创建输出目录
    fig_dir = 'figures';
    if ~exist(fig_dir, 'dir')
        [status, msg] = mkdir(fig_dir);
        if status == 0
            error('无法创建目录 %s: %s', fig_dir, msg);
        end
    end
    
    % 计算线性拟合（用于子图4）
    p = polyfit(V_ref_deviation_percent, errors * 1000, 1);
    
    % 子图1：V_ref偏差 vs 测量误差
    figure('Position', [100, 100, 800, 600]);
    plot(V_ref_deviation_percent, errors * 1000, 'b-', 'LineWidth', 2);
    xlabel('基准电压偏差 (%)', 'FontSize', 12);
    ylabel('测量误差 (mV)', 'FontSize', 12);
    title('基准电压偏差对测量误差的影响', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    hold on;
    plot([0, 0], ylim, 'r--', 'LineWidth', 1);
    plot(xlim, [0, 0], 'r--', 'LineWidth', 1);
    legend('测量误差', '零偏差线', 'Location', 'best');
    fig_path = fullfile(fig_dir, 'vref_error_vs_deviation.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图2：V_ref偏差 vs 相对误差
    figure('Position', [100, 100, 800, 600]);
    plot(V_ref_deviation_percent, relative_errors, 'b-', 'LineWidth', 2);
    xlabel('基准电压偏差 (%)', 'FontSize', 12);
    ylabel('相对误差 (%)', 'FontSize', 12);
    title('基准电压偏差对相对误差的影响', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    hold on;
    plot([0, 0], ylim, 'k--', 'LineWidth', 1);
    plot(xlim, [0, 0], 'k--', 'LineWidth', 1);
    fig_path = fullfile(fig_dir, 'vref_relative_error.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图3：稳定性指标 vs 精度指标（双Y轴）
    figure('Position', [100, 100, 800, 600]);
    yyaxis left;
    plot(V_ref_deviation_percent, abs(V_ref_deviation_percent), 'g-', 'LineWidth', 2);
    ylabel('基准电压稳定性指标 |偏差| (%)', 'FontSize', 12);
    yyaxis right;
    plot(V_ref_deviation_percent, relative_errors, 'b-', 'LineWidth', 2);
    ylabel('测量精度指标 相对误差 (%)', 'FontSize', 12);
    xlabel('基准电压偏差 (%)', 'FontSize', 12);
    title('基准电压稳定性与测量精度的关系', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('稳定性指标', '精度指标', 'Location', 'best');
    fig_path = fullfile(fig_dir, 'vref_stability_vs_accuracy.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图4：散点图显示线性关系
    figure('Position', [100, 100, 800, 600]);
    scatter(V_ref_deviation_percent, errors * 1000, 50, 'filled', 'MarkerFaceColor', [0.2 0.6 0.8]);
    xlabel('基准电压偏差 (%)', 'FontSize', 12);
    ylabel('测量误差 (mV)', 'FontSize', 12);
    title('基准电压偏差与测量误差的线性关系', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    hold on;
    % 拟合直线
    fit_line = polyval(p, V_ref_deviation_percent);
    plot(V_ref_deviation_percent, fit_line, 'r--', 'LineWidth', 2);
    legend('仿真数据', sprintf('线性拟合: y = %.3f x + %.3f', p(1), p(2)), ...
        'Location', 'best');
    fig_path = fullfile(fig_dir, 'vref_linear_relationship.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 输出结论
    fprintf('\n=== 结论1验证结果 ===\n');
    fprintf('基准电压偏差范围: %.2f%% 到 %.2f%%\n', ...
        min(V_ref_deviation_percent), max(V_ref_deviation_percent));
    fprintf('最大测量误差: %.4f mV\n', max(abs(errors)) * 1000);
    fprintf('最大相对误差: %.4f%%\n', max(relative_errors));
    fprintf('线性拟合斜率: %.4f mV/%%\n', p(1));
    fprintf('结论：基准电压偏差与测量误差呈线性关系，稳定性越高，测量精度越高。\n\n');
end

