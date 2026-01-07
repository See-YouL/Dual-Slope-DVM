function results = simulate_powerline_noise()
%SIMULATE_POWERLINE_NOISE 工频干扰对测量结果的影响仿真
%   验证结论4：当积分时间T_1取工频周期的整数倍时，工频干扰被完全抵消
%
%   输出:
%       results: 包含仿真结果的表格

    % 仿真参数设置
    V_in = 2.5;  % 输入电压 2.5V
    V_ref = 5.0;  % 基准电压 5V
    f_clk = 1e6;  % 时钟频率 1MHz
    
    % 工频参数
    f_powerline = 50;  % 工频 50Hz
    T_powerline = 1 / f_powerline;  % 工频周期 20ms
    A_noise = 0.1;  % 干扰幅度 100mV
    
    % 测试不同的积分时间
    % 包括工频周期的整数倍和非整数倍
    T1_integer = [1, 2, 3, 4, 5] * T_powerline;  % 整数倍：20ms, 40ms, 60ms, 80ms, 100ms
    T1_noninteger = [1.1, 1.5, 2.3, 3.7, 4.9] * T_powerline;  % 非整数倍
    T1_values = [T1_integer, T1_noninteger];
    T1_labels = cell(length(T1_values), 1);
    for i = 1:length(T1_integer)
        T1_labels{i} = sprintf('%.0f×T_{50Hz} = %.0f ms', ...
            T1_integer(i)/T_powerline, T1_integer(i)*1000);
    end
    for i = 1:length(T1_noninteger)
        T1_labels{length(T1_integer)+i} = sprintf('%.1f×T_{50Hz} = %.1f ms', ...
            T1_noninteger(i)/T_powerline, T1_noninteger(i)*1000);
    end
    is_integer = [true(1, length(T1_integer)), false(1, length(T1_noninteger))];
    
    % 测试不同相位的干扰
    phases = [0, pi/4, pi/2, 3*pi/4, pi];  % 不同初始相位
    
    % 理想条件（无其他非理想因素）
    V_offset = 0;
    V_bias = 0;
    R_leak = inf;
    C = 1e-6;
    R = 100e3;
    
    % 初始化结果数组
    n_T1 = length(T1_values);
    n_phases = length(phases);
    errors = zeros(n_T1, n_phases);
    rejection_ratios = zeros(n_T1, n_phases);
    
    fprintf('正在进行工频干扰仿真...\n');
    
    % 对每个积分时间和相位进行仿真
    for i = 1:n_T1
        T1 = T1_values(i);
        for j = 1:n_phases
            phi = phases(j);
            % 创建工频干扰信号函数
            noise_signal = @(t) A_noise * sin(2*pi*f_powerline*t + phi);
            
            [~, V_measured, error, ~] = dual_slope_dvm(V_in, V_ref, T1, f_clk, ...
                V_offset, V_bias, R_leak, C, R, noise_signal);
            
            errors(i, j) = error;
            % 计算干扰抑制比（理想情况下应该是无穷大，这里用误差的倒数）
            if abs(error) > 1e-9
                rejection_ratios(i, j) = A_noise / abs(error);
            else
                rejection_ratios(i, j) = inf;
            end
        end
        fprintf('  完成 T1 = %.1f ms\n', T1 * 1000);
    end
    
    % 计算平均值（对不同相位）
    errors_mean = mean(abs(errors), 2);  % 已经是列向量
    errors_max = max(abs(errors), [], 2);  % 已经是列向量
    errors_min = min(abs(errors), [], 2);  % 已经是列向量
    rejection_ratios_mean = mean(rejection_ratios, 2);  % 已经是列向量
    
    % 创建结果表格（确保所有向量都是列向量）
    T1_ratio = (T1_values(:) / T_powerline);  % 确保是列向量
    T1_ms_col = T1_values(:) * 1000;  % 确保是列向量
    is_integer_col = is_integer(:);  % 确保是列向量
    
    results = table(T1_ms_col, T1_ratio, is_integer_col, errors_mean*1000, ...
        errors_min*1000, errors_max*1000, rejection_ratios_mean, ...
        'VariableNames', {'T1_ms', 'T1_T50Hz_Ratio', 'Is_Integer_Multiple', ...
        'Error_Mean_mV', 'Error_Min_mV', 'Error_Max_mV', 'Rejection_Ratio'});
    
    % 保存表格到Excel
    writetable(results, 'results_powerline_noise.xlsx');
    fprintf('结果已保存到 results_powerline_noise.xlsx\n');
    
    % 创建输出目录
    fig_dir = 'figures';
    if ~exist(fig_dir, 'dir')
        [status, msg] = mkdir(fig_dir);
        if status == 0
            error('无法创建目录 %s: %s', fig_dir, msg);
        end
    end
    
    integer_indices = find(is_integer);
    noninteger_indices = find(~is_integer);
    T1_int_example = T1_integer(2);  % 40ms (2倍周期)
    T1_nonint_example = T1_noninteger(2);  % 30ms (1.5倍周期)
    error_int_mean = mean(errors_mean(integer_indices)) * 1000;
    error_nonint_mean = mean(errors_mean(noninteger_indices)) * 1000;
    
    % 子图1：T1/工频周期 vs 测量误差（对比整数倍和非整数倍）
    figure('Position', [100, 100, 800, 600]);
    plot(T1_ratio(integer_indices), errors_mean(integer_indices) * 1000, ...
        'go', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', '整数倍周期');
    hold on;
    plot(T1_ratio(noninteger_indices), errors_mean(noninteger_indices) * 1000, ...
        'ro', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', '非整数倍周期');
    xlabel('T_1 / T_{50Hz}', 'FontSize', 12);
    ylabel('测量误差 (mV)', 'FontSize', 12);
    title('积分时间与工频周期比值对测量误差的影响', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('Location', 'best');
    for i = 1:length(integer_indices)
        text(T1_ratio(integer_indices(i)), errors_mean(integer_indices(i)) * 1000, ...
            sprintf('  %.0f×', T1_ratio(integer_indices(i))), ...
            'FontSize', 10, 'Color', 'green');
    end
    fig_path = fullfile(fig_dir, 'powerline_error_vs_ratio.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图2：干扰抑制比对比
    figure('Position', [100, 100, 800, 600]);
    rejection_plot = rejection_ratios_mean;
    rejection_plot(rejection_plot == inf) = max(rejection_plot(isfinite(rejection_plot))) * 1.5;
    x_labels = [T1_labels(integer_indices); T1_labels(noninteger_indices)];
    bar(1:length(T1_values), rejection_plot, 'FaceColor', [0.6 0.8 0.9]);
    set(gca, 'XTick', 1:length(T1_values), 'XTickLabel', x_labels, ...
        'XTickLabelRotation', 45);
    ylabel('干扰抑制比', 'FontSize', 12);
    title('不同积分时间下的工频干扰抑制比', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    for i = 1:length(integer_indices)
        bar(integer_indices(i), rejection_plot(integer_indices(i)), ...
            'FaceColor', 'green');
    end
    fig_path = fullfile(fig_dir, 'powerline_rejection_ratio.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图3：时域波形对比（整数倍 vs 非整数倍）
    figure('Position', [100, 100, 800, 600]);
    t1 = 0:1e-6:T1_int_example;
    noise1 = A_noise * sin(2*pi*f_powerline*t1);
    plot(t1*1000, noise1, 'g-', 'LineWidth', 1.5, 'DisplayName', sprintf('T_1 = %.0f ms (整数倍)', T1_int_example*1000));
    hold on;
    t2 = 0:1e-6:T1_nonint_example;
    noise2 = A_noise * sin(2*pi*f_powerline*t2);
    plot(t2*1000, noise2, 'r-', 'LineWidth', 1.5, 'DisplayName', sprintf('T_1 = %.1f ms (非整数倍)', T1_nonint_example*1000));
    xlabel('时间 (ms)', 'FontSize', 12);
    ylabel('干扰信号幅度 (V)', 'FontSize', 12);
    title('工频干扰时域波形对比', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('Location', 'best');
    fig_path = fullfile(fig_dir, 'powerline_time_domain.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图4：误差范围（最小-最大）
    figure('Position', [100, 100, 800, 600]);
    errorbar(T1_ratio, errors_mean * 1000, ...
        (errors_mean - errors_min) * 1000, ...
        (errors_max - errors_mean) * 1000, ...
        'bo', 'LineWidth', 1.5, 'MarkerSize', 8, 'CapSize', 8);
    hold on;
    plot(T1_ratio(integer_indices), errors_mean(integer_indices) * 1000, ...
        'go', 'MarkerSize', 12, 'LineWidth', 2);
    xlabel('T_1 / T_{50Hz}', 'FontSize', 12);
    ylabel('测量误差 (mV)', 'FontSize', 12);
    title('测量误差范围（不同相位）', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('误差范围', '整数倍周期', 'Location', 'best');
    fig_path = fullfile(fig_dir, 'powerline_error_range.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图5：频谱分析（FFT显示干扰抑制效果）
    figure('Position', [100, 100, 800, 600]);
    fs = 1e6;
    t_fft = 0:1/fs:max(T1_values);
    noise_int = A_noise * sin(2*pi*f_powerline*t_fft);
    noise_int_windowed = noise_int(1:round(T1_int_example*fs)+1);
    noise_nonint = A_noise * sin(2*pi*f_powerline*t_fft);
    noise_nonint_windowed = noise_nonint(1:round(T1_nonint_example*fs)+1);
    N_int = length(noise_int_windowed);
    f_int = (0:N_int-1) * fs / N_int;
    Y_int = abs(fft(noise_int_windowed));
    N_nonint = length(noise_nonint_windowed);
    f_nonint = (0:N_nonint-1) * fs / N_nonint;
    Y_nonint = abs(fft(noise_nonint_windowed));
    idx_int = f_int <= 200;
    idx_nonint = f_nonint <= 200;
    semilogy(f_int(idx_int), Y_int(idx_int), 'g-', 'LineWidth', 2, ...
        'DisplayName', sprintf('T_1 = %.0f ms (整数倍)', T1_int_example*1000));
    hold on;
    semilogy(f_nonint(idx_nonint), Y_nonint(idx_nonint), 'r-', 'LineWidth', 2, ...
        'DisplayName', sprintf('T_1 = %.1f ms (非整数倍)', T1_nonint_example*1000));
    xlabel('频率 (Hz)', 'FontSize', 12);
    ylabel('幅度 (对数)', 'FontSize', 12);
    title('工频干扰频谱分析', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('Location', 'best');
    xlim([0, 200]);
    fig_path = fullfile(fig_dir, 'powerline_spectrum.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图6：干扰抑制效果总结
    figure('Position', [100, 100, 800, 600]);
    bar_data = [error_int_mean, error_nonint_mean];
    bar(bar_data, 'FaceColor', [0.7 0.5 0.8]);
    set(gca, 'XTickLabel', {'整数倍周期', '非整数倍周期'});
    ylabel('平均测量误差 (mV)', 'FontSize', 12);
    title('整数倍 vs 非整数倍周期干扰抑制对比', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    for i = 1:length(bar_data)
        text(i, bar_data(i), sprintf('%.4f mV', bar_data(i)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 11, 'FontWeight', 'bold');
    end
    fig_path = fullfile(fig_dir, 'powerline_comparison.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 输出结论
    fprintf('\n=== 结论4验证结果 ===\n');
    fprintf('工频频率: %.0f Hz (周期: %.0f ms)\n', f_powerline, T_powerline*1000);
    fprintf('干扰幅度: %.1f mV\n', A_noise*1000);
    fprintf('整数倍周期平均误差: %.6f mV\n', error_int_mean);
    fprintf('非整数倍周期平均误差: %.6f mV\n', error_nonint_mean);
    fprintf('干扰抑制比提升: %.2fx\n', error_nonint_mean / max(error_int_mean, 1e-6));
    fprintf('结论：当T_1为工频周期整数倍时，工频干扰被完全抵消，测量误差接近零。\n\n');
end

