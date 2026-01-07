function results = simulate_clock_error()
%SIMULATE_CLOCK_ERROR 时钟周期量化误差对测量结果的影响仿真
%   验证结论2：在积分时间T_1一定的条件下，提高时钟频率减小T_{clk}
%   有利于降低量化误差，提高测量分辨率
%
%   输出:
%       results: 包含仿真结果的表格

    % 仿真参数设置
    V_in = 2.5;  % 输入电压 2.5V
    V_ref = 5.0;  % 基准电压 5V
    T1 = 0.1;  % 固定积分时间 100ms
    
    % 时钟频率范围：100kHz 到 10MHz（对数分布）
    f_clk_min = 100e3;
    f_clk_max = 10e6;
    n_points = 50;
    f_clk_values = logspace(log10(f_clk_min), log10(f_clk_max), n_points)';
    T_clk_values = 1 ./ f_clk_values;
    
    % 理想条件（无其他非理想因素）
    V_offset = 0;
    V_bias = 0;
    R_leak = inf;
    C = 1e-6;
    R = 100e3;
    noise_signal = @(t) 0;
    
    % 初始化结果数组
    quantization_errors = zeros(n_points, 1);
    relative_errors = zeros(n_points, 1);
    resolutions = zeros(n_points, 1);
    V_measured_values = zeros(n_points, 1);
    
    % 对每个时钟频率进行仿真
    fprintf('正在进行时钟量化误差仿真...\n');
    for i = 1:n_points
        f_clk = f_clk_values(i);
        [T2, V_measured, error, ~] = dual_slope_dvm(V_in, V_ref, T1, f_clk, ...
            V_offset, V_bias, R_leak, C, R, noise_signal);
        
        % 计算量化误差（理论T2与实际T2的差）
        % 理论T2 = V_in * T1 / V_ref
        T2_theoretical = V_in * T1 / V_ref;
        T_clk = 1 / f_clk;
        quantization_error = abs(T2 - T2_theoretical);  % 量化误差（时间）
        quantization_error_voltage = quantization_error * V_ref / T1;  % 转换为电压误差
        
        quantization_errors(i) = quantization_error_voltage;
        relative_errors(i) = abs(error / V_in) * 100;
        resolutions(i) = V_ref * T_clk / T1;  % 测量分辨率 = V_ref * T_clk / T1
        V_measured_values(i) = V_measured;
        
        if mod(i, 10) == 0
            fprintf('  进度: %d/%d (f_clk = %.2f MHz)\n', i, n_points, f_clk/1e6);
        end
    end
    
    % 创建结果表格
    results = table(f_clk_values/1e6, T_clk_values*1e6, quantization_errors*1000, ...
        relative_errors, resolutions*1000, V_measured_values, ...
        'VariableNames', {'Clock_Frequency_MHz', 'Clock_Period_us', ...
        'Quantization_Error_mV', 'Relative_Error_Percent', ...
        'Resolution_mV', 'V_measured_V'});
    
    % 保存表格到Excel
    writetable(results, 'results_clock_error.xlsx');
    fprintf('结果已保存到 results_clock_error.xlsx\n');
    
    % 创建输出目录
    fig_dir = 'figures';
    if ~exist(fig_dir, 'dir')
        [status, msg] = mkdir(fig_dir);
        if status == 0
            error('无法创建目录 %s: %s', fig_dir, msg);
        end
    end
    
    % 子图1：时钟频率 vs 量化误差（对数坐标）
    figure('Position', [100, 100, 800, 600]);
    semilogx(f_clk_values/1e6, quantization_errors * 1000, 'b-', 'LineWidth', 2);
    xlabel('时钟频率 (MHz)', 'FontSize', 12);
    ylabel('量化误差 (mV)', 'FontSize', 12);
    title('时钟频率对量化误差的影响', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    fig_path = fullfile(fig_dir, 'clock_freq_vs_quantization_error.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图2：T_clk vs 量化误差（对数坐标）
    figure('Position', [100, 100, 800, 600]);
    semilogx(T_clk_values*1e6, quantization_errors * 1000, 'b-', 'LineWidth', 2);
    xlabel('时钟周期 T_{clk} (μs)', 'FontSize', 12);
    ylabel('量化误差 (mV)', 'FontSize', 12);
    title('时钟周期对量化误差的影响', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    fig_path = fullfile(fig_dir, 'clock_period_vs_quantization_error.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图3：时钟频率 vs 测量分辨率（对数坐标）
    figure('Position', [100, 100, 800, 600]);
    semilogx(f_clk_values/1e6, resolutions * 1000, 'b-', 'LineWidth', 2);
    xlabel('时钟频率 (MHz)', 'FontSize', 12);
    ylabel('测量分辨率 (mV)', 'FontSize', 12);
    title('时钟频率对测量分辨率的影响', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    fig_path = fullfile(fig_dir, 'clock_freq_vs_resolution.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图4：T_clk vs 测量分辨率（对数坐标）
    figure('Position', [100, 100, 800, 600]);
    semilogx(T_clk_values*1e6, resolutions * 1000, 'b-', 'LineWidth', 2);
    xlabel('时钟周期 T_{clk} (μs)', 'FontSize', 12);
    ylabel('测量分辨率 (mV)', 'FontSize', 12);
    title('时钟周期对测量分辨率的影响', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    fig_path = fullfile(fig_dir, 'clock_period_vs_resolution.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图5：时钟频率 vs 相对误差（对数坐标）
    figure('Position', [100, 100, 800, 600]);
    semilogx(f_clk_values/1e6, relative_errors, 'b-', 'LineWidth', 2);
    xlabel('时钟频率 (MHz)', 'FontSize', 12);
    ylabel('相对误差 (%)', 'FontSize', 12);
    title('时钟频率对相对误差的影响', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    fig_path = fullfile(fig_dir, 'clock_freq_vs_relative_error.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图6：分辨率对比柱状图（选择几个典型频率点）
    figure('Position', [100, 100, 800, 600]);
    selected_indices = [1, 10, 20, 30, 40, 50];
    selected_freqs = f_clk_values(selected_indices) / 1e6;
    selected_resolutions = resolutions(selected_indices) * 1000;
    bar(selected_freqs, selected_resolutions, 'FaceColor', [0.3 0.7 0.9]);
    xlabel('时钟频率 (MHz)', 'FontSize', 12);
    ylabel('测量分辨率 (mV)', 'FontSize', 12);
    title('不同时钟频率下的测量分辨率对比', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), selected_freqs, 'UniformOutput', false));
    fig_path = fullfile(fig_dir, 'clock_resolution_comparison.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 输出结论
    fprintf('\n=== 结论2验证结果 ===\n');
    fprintf('时钟频率范围: %.2f kHz 到 %.2f MHz\n', ...
        min(f_clk_values)/1e3, max(f_clk_values)/1e6);
    fprintf('时钟周期范围: %.2f μs 到 %.2f μs\n', ...
        min(T_clk_values)*1e6, max(T_clk_values)*1e6);
    fprintf('最大量化误差: %.4f mV (f_clk = %.2f kHz)\n', ...
        max(quantization_errors) * 1000, f_clk_values(quantization_errors == max(quantization_errors))/1e3);
    fprintf('最小量化误差: %.4f mV (f_clk = %.2f MHz)\n', ...
        min(quantization_errors) * 1000, f_clk_values(quantization_errors == min(quantization_errors))/1e6);
    fprintf('最佳分辨率: %.4f mV (f_clk = %.2f MHz)\n', ...
        min(resolutions) * 1000, f_clk_values(resolutions == min(resolutions))/1e6);
    fprintf('结论：提高时钟频率减小T_{clk}可以显著降低量化误差，提高测量分辨率。\n\n');
end

