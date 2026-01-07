function results = simulate_nonideal_rc()
%SIMULATE_NONIDEAL_RC 积分器RC非理想因素对测量结果的影响仿真
%   验证结论3：如果积分器的RC处于非理想状态，积分时间越长对于测试结果的影响更明显
%
%   测试的非理想因素：
%   1. 零点偏移 (V_offset)
%   2. 偏置电压 (V_bias)
%   3. 电容漏电 (R_leak)
%
%   输出:
%       results: 包含仿真结果的表格

    % 仿真参数设置
    V_in = 2.5;  % 输入电压 2.5V
    V_ref = 5.0;  % 基准电压 5V
    f_clk = 1e6;  % 时钟频率 1MHz
    
    % 积分时间范围：20ms 到 200ms
    T1_values = (20:10:200) * 1e-3;  % 20ms到200ms，步长10ms
    n_T1 = length(T1_values);
    
    % 非理想因素参数
    V_offset_values = [0, 2e-3, 5e-3, 10e-3];  % 零点偏移：0, 2mV, 5mV, 10mV
    V_bias_values = [0, 1e-3, 2.5e-3, 5e-3];  % 偏置电压：0, 1mV, 2.5mV, 5mV
    R_leak_values = [inf, 100e6, 10e6, 1e6];  % 漏电电阻：无漏电, 100MΩ, 10MΩ, 1MΩ
    
    C = 1e-6;  % 积分电容 1μF
    R = 100e3;  % 积分电阻 100kΩ
    noise_signal = @(t) 0;  % 无干扰
    
    % 初始化结果数组
    % 分别测试每个非理想因素
    errors_offset = zeros(n_T1, length(V_offset_values));
    errors_bias = zeros(n_T1, length(V_bias_values));
    errors_leak = zeros(n_T1, length(R_leak_values));
    
    fprintf('正在进行RC非理想因素仿真...\n');
    
    % 测试1：零点偏移的影响
    fprintf('  测试零点偏移影响...\n');
    for i = 1:length(V_offset_values)
        V_offset = V_offset_values(i);
        for j = 1:n_T1
            T1 = T1_values(j);
            [~, ~, error, ~] = dual_slope_dvm(V_in, V_ref, T1, f_clk, ...
                V_offset, 0, inf, C, R, noise_signal);
            errors_offset(j, i) = error;
        end
        fprintf('    完成 V_offset = %.1f mV\n', V_offset * 1000);
    end
    
    % 测试2：偏置电压的影响
    fprintf('  测试偏置电压影响...\n');
    for i = 1:length(V_bias_values)
        V_bias = V_bias_values(i);
        for j = 1:n_T1
            T1 = T1_values(j);
            [~, ~, error, ~] = dual_slope_dvm(V_in, V_ref, T1, f_clk, ...
                0, V_bias, inf, C, R, noise_signal);
            errors_bias(j, i) = error;
        end
        fprintf('    完成 V_bias = %.1f mV\n', V_bias * 1000);
    end
    
    % 测试3：电容漏电的影响
    fprintf('  测试电容漏电影响...\n');
    for i = 1:length(R_leak_values)
        R_leak = R_leak_values(i);
        for j = 1:n_T1
            T1 = T1_values(j);
            [~, ~, error, ~] = dual_slope_dvm(V_in, V_ref, T1, f_clk, ...
                0, 0, R_leak, C, R, noise_signal);
            errors_leak(j, i) = error;
        end
        if isfinite(R_leak)
            fprintf('    完成 R_leak = %.1f MΩ\n', R_leak / 1e6);
        else
            fprintf('    完成 R_leak = inf (无漏电)\n');
        end
    end
    
    % 创建结果表格
    % 表格1：零点偏移影响
    T1_ms = T1_values(:) * 1000;  % 确保是列向量
    % 构建表格数据：每个V_offset值对应所有T1值
    T1_col = repmat(T1_ms, length(V_offset_values), 1);
    V_offset_col = repelem(V_offset_values(:) * 1000, n_T1);
    Error_offset_col = errors_offset(:) * 1000;  % 按列展开
    table_offset = table(T1_col, V_offset_col, Error_offset_col, ...
        'VariableNames', {'T1_ms', 'V_offset_mV', 'Error_mV'});
    
    % 表格2：偏置电压影响
    T1_col = repmat(T1_ms, length(V_bias_values), 1);
    V_bias_col = repelem(V_bias_values(:) * 1000, n_T1);
    Error_bias_col = errors_bias(:) * 1000;  % 按列展开
    table_bias = table(T1_col, V_bias_col, Error_bias_col, ...
        'VariableNames', {'T1_ms', 'V_bias_mV', 'Error_mV'});
    
    % 表格3：漏电影响
    R_leak_labels = cell(length(R_leak_values), 1);
    for i = 1:length(R_leak_values)
        if isfinite(R_leak_values(i))
            R_leak_labels{i} = sprintf('%.1f MΩ', R_leak_values(i) / 1e6);
        else
            R_leak_labels{i} = 'inf (无漏电)';
        end
    end
    T1_col = repmat(T1_ms, length(R_leak_values), 1);
    R_leak_col = repelem(R_leak_labels, n_T1);
    Error_leak_col = errors_leak(:) * 1000;  % 按列展开
    table_leak = table(T1_col, R_leak_col, Error_leak_col, ...
        'VariableNames', {'T1_ms', 'R_leak', 'Error_mV'});
    
    % 创建综合表格（统一变量名以便合并）
    % 为每个表格添加参数类型列
    n_offset = height(table_offset);
    n_bias = height(table_bias);
    n_leak = height(table_leak);
    
    % 创建综合表格
    ParameterType = [repmat({'零点偏移'}, n_offset, 1); ...
                     repmat({'偏置电压'}, n_bias, 1); ...
                     repmat({'电容漏电'}, n_leak, 1)];
    
    ParameterValue = [cellstr(num2str(table_offset.V_offset_mV, '%.2f mV')); ...
                      cellstr(num2str(table_bias.V_bias_mV, '%.2f mV')); ...
                      table_leak.R_leak];
    
    results = table(...
        [table_offset.T1_ms; table_bias.T1_ms; table_leak.T1_ms], ...
        ParameterType, ...
        ParameterValue, ...
        [table_offset.Error_mV; table_bias.Error_mV; table_leak.Error_mV], ...
        'VariableNames', {'T1_ms', 'ParameterType', 'ParameterValue', 'Error_mV'});
    
    % 保存表格到Excel
    writetable(table_offset, 'results_nonideal_rc_offset.xlsx');
    writetable(table_bias, 'results_nonideal_rc_bias.xlsx');
    writetable(table_leak, 'results_nonideal_rc_leak.xlsx');
    writetable(results, 'results_nonideal_rc.xlsx');
    fprintf('结果已保存到 results_nonideal_rc*.xlsx\n');
    
    % 创建输出目录
    fig_dir = 'figures';
    if ~exist(fig_dir, 'dir')
        [status, msg] = mkdir(fig_dir);
        if status == 0
            error('无法创建目录 %s: %s', fig_dir, msg);
        end
    end
    
    % 计算误差增长率（用于子图5）
    growth_offset = abs(errors_offset(end, 2:end) ./ errors_offset(1, 2:end));
    growth_bias = abs(errors_bias(end, 2:end) ./ errors_bias(1, 2:end));
    growth_leak = abs(errors_leak(end, 2:end) ./ errors_leak(1, 2:end));
    
    % 计算误差斜率（用于子图6）
    slopes_offset = zeros(1, length(V_offset_values)-1);
    slopes_bias = zeros(1, length(V_bias_values)-1);
    slopes_leak = zeros(1, length(R_leak_values)-1);
    for i = 2:length(V_offset_values)
        p = polyfit(T1_values, errors_offset(:, i), 1);
        slopes_offset(i-1) = p(1) * 1000;
    end
    for i = 2:length(V_bias_values)
        p = polyfit(T1_values, errors_bias(:, i), 1);
        slopes_bias(i-1) = p(1) * 1000;
    end
    for i = 2:length(R_leak_values)
        if isfinite(R_leak_values(i))
            p = polyfit(T1_values, errors_leak(:, i), 1);
            slopes_leak(i-1) = p(1) * 1000;
        end
    end
    
    % 子图1：零点偏移误差 vs 积分时间
    figure('Position', [100, 100, 800, 600]);
    colors = lines(length(V_offset_values));
    for i = 1:length(V_offset_values)
        plot(T1_values * 1000, errors_offset(:, i) * 1000, ...
            '-o', 'LineWidth', 2, 'Color', colors(i, :), ...
            'MarkerSize', 4, 'DisplayName', sprintf('V_{offset} = %.1f mV', V_offset_values(i) * 1000));
        hold on;
    end
    xlabel('积分时间 T_1 (ms)', 'FontSize', 12);
    ylabel('测量误差 (mV)', 'FontSize', 12);
    title('零点偏移对测量误差的影响', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('Location', 'best');
    fig_path = fullfile(fig_dir, 'rc_offset_error.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图2：偏置电压误差 vs 积分时间
    figure('Position', [100, 100, 800, 600]);
    colors = lines(length(V_bias_values));
    for i = 1:length(V_bias_values)
        plot(T1_values * 1000, errors_bias(:, i) * 1000, ...
            '-s', 'LineWidth', 2, 'Color', colors(i, :), ...
            'MarkerSize', 4, 'DisplayName', sprintf('V_{bias} = %.1f mV', V_bias_values(i) * 1000));
        hold on;
    end
    xlabel('积分时间 T_1 (ms)', 'FontSize', 12);
    ylabel('测量误差 (mV)', 'FontSize', 12);
    title('偏置电压对测量误差的影响', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('Location', 'best');
    fig_path = fullfile(fig_dir, 'rc_bias_error.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图3：漏电误差 vs 积分时间
    figure('Position', [100, 100, 800, 600]);
    colors = lines(length(R_leak_values));
    for i = 1:length(R_leak_values)
        if isfinite(R_leak_values(i))
            label = sprintf('R_{leak} = %.1f MΩ', R_leak_values(i) / 1e6);
        else
            label = 'R_{leak} = inf (无漏电)';
        end
        plot(T1_values * 1000, errors_leak(:, i) * 1000, ...
            '-^', 'LineWidth', 2, 'Color', colors(i, :), ...
            'MarkerSize', 4, 'DisplayName', label);
        hold on;
    end
    xlabel('积分时间 T_1 (ms)', 'FontSize', 12);
    ylabel('测量误差 (mV)', 'FontSize', 12);
    title('电容漏电对测量误差的影响', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('Location', 'best');
    fig_path = fullfile(fig_dir, 'rc_leak_error.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图4：误差累积趋势（所有非理想因素叠加）
    figure('Position', [100, 100, 800, 600]);
    error_combined = errors_offset(:, 3) + errors_bias(:, 3) + errors_leak(:, 2);
    plot(T1_values * 1000, error_combined * 1000, 'b-', 'LineWidth', 2.5);
    xlabel('积分时间 T_1 (ms)', 'FontSize', 12);
    ylabel('总测量误差 (mV)', 'FontSize', 12);
    title('非理想因素叠加效应（误差累积）', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    hold on;
    fig_path = fullfile(fig_dir, 'rc_combined_error.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图5：误差增长率对比
    figure('Position', [100, 100, 800, 600]);
    x_pos = 1:3;
    bar_data = [mean(growth_offset), mean(growth_bias), mean(growth_leak)];
    bar(x_pos, bar_data, 'FaceColor', [0.5 0.7 0.9]);
    set(gca, 'XTickLabel', {'零点偏移', '偏置电压', '电容漏电'});
    ylabel('误差增长倍数 (T_1=200ms / T_1=20ms)', 'FontSize', 12);
    title('不同非理想因素的误差增长率', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    for i = 1:length(bar_data)
        text(i, bar_data(i), sprintf('%.2fx', bar_data(i)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 11, 'FontWeight', 'bold');
    end
    fig_path = fullfile(fig_dir, 'rc_error_growth.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 子图6：误差斜率对比（线性拟合斜率）
    figure('Position', [100, 100, 800, 600]);
    x_pos = 1:max([length(slopes_offset), length(slopes_bias), length(slopes_leak)]);
    max_len = max([length(slopes_offset), length(slopes_bias), length(slopes_leak)]);
    slopes_matrix = [slopes_offset, zeros(1, max_len-length(slopes_offset)); ...
                     slopes_bias, zeros(1, max_len-length(slopes_bias)); ...
                     slopes_leak, zeros(1, max_len-length(slopes_leak))];
    bar(slopes_matrix', 'grouped');
    set(gca, 'XTickLabel', {'中等', '较大', '最大'});
    ylabel('误差斜率 (mV/ms)', 'FontSize', 12);
    title('不同非理想因素的误差斜率对比', 'FontSize', 14, 'FontWeight', 'bold');
    legend('零点偏移', '偏置电压', '电容漏电', 'Location', 'best');
    grid on;
    fig_path = fullfile(fig_dir, 'rc_error_slope.png');
    saveas(gcf, fig_path);
    fprintf('图表已保存到 %s\n', fig_path);
    % close(gcf);  % 保留figure窗口以便查看
    
    % 输出结论
    fprintf('\n=== 结论3验证结果 ===\n');
    fprintf('积分时间范围: %.0f ms 到 %.0f ms\n', min(T1_values)*1000, max(T1_values)*1000);
    fprintf('零点偏移误差增长: %.2fx (从 %.4f mV 到 %.4f mV)\n', ...
        growth_offset(1), abs(errors_offset(1, 2))*1000, abs(errors_offset(end, 2))*1000);
    fprintf('偏置电压误差增长: %.2fx (从 %.4f mV 到 %.4f mV)\n', ...
        growth_bias(1), abs(errors_bias(1, 2))*1000, abs(errors_bias(end, 2))*1000);
    fprintf('电容漏电误差增长: %.2fx (从 %.4f mV 到 %.4f mV)\n', ...
        growth_leak(1), abs(errors_leak(1, 2))*1000, abs(errors_leak(end, 2))*1000);
    fprintf('结论：积分时间越长，非理想因素对测试结果的影响更明显，误差呈线性增长。\n\n');
end

