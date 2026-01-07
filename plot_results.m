function plot_results()
%PLOT_RESULTS 综合结果可视化函数
%   生成所有仿真结果的综合可视化图表
%
%   注意：此函数需要在运行完所有仿真模块后调用

    fprintf('正在生成综合可视化图表...\n');
    
    % 检查结果文件是否存在
    result_files = {'results_vref_error.xlsx', 'results_clock_error.xlsx', ...
        'results_nonideal_rc.xlsx', 'results_powerline_noise.xlsx'};
    
    for i = 1:length(result_files)
        if ~exist(result_files{i}, 'file')
            warning('结果文件 %s 不存在，请先运行相应的仿真模块。', result_files{i});
        end
    end
    
    % 创建综合对比图
    figure('Position', [100, 100, 1600, 1200]);
    
    % 读取所有结果数据
    try
        data_vref = readtable('results_vref_error.xlsx');
        data_clock = readtable('results_clock_error.xlsx');
        % 读取RC非理想因素的单独表格
        data_rc_offset = readtable('results_nonideal_rc_offset.xlsx');
        data_rc_bias = readtable('results_nonideal_rc_bias.xlsx');
        data_rc_leak = readtable('results_nonideal_rc_leak.xlsx');
        data_rc = readtable('results_nonideal_rc.xlsx');  % 综合表格
        data_noise = readtable('results_powerline_noise.xlsx');
    catch ME
        error('无法读取结果文件：%s', ME.message);
    end
    
    % 子图1：四个结论的综合对比（归一化显示）
    subplot(3, 3, 1);
    % 归一化到0-1范围
    vref_norm = (data_vref.V_ref_Deviation_Percent - min(data_vref.V_ref_Deviation_Percent)) / ...
        (max(data_vref.V_ref_Deviation_Percent) - min(data_vref.V_ref_Deviation_Percent));
    error_vref_norm = abs(data_vref.Relative_Error_Percent) / max(abs(data_vref.Relative_Error_Percent));
    plot(vref_norm, error_vref_norm, 'b-', 'LineWidth', 2, 'DisplayName', '基准电压稳定性');
    xlabel('归一化参数', 'FontSize', 10);
    ylabel('归一化误差', 'FontSize', 10);
    title('结论1：基准电压稳定性影响', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
    legend('Location', 'best');
    
    subplot(3, 3, 2);
    freq_norm = (log10(data_clock.Clock_Frequency_MHz) - log10(min(data_clock.Clock_Frequency_MHz))) / ...
        (log10(max(data_clock.Clock_Frequency_MHz)) - log10(min(data_clock.Clock_Frequency_MHz)));
    error_clock_norm = data_clock.Quantization_Error_mV / max(data_clock.Quantization_Error_mV);
    plot(freq_norm, error_clock_norm, 'b-', 'LineWidth', 2, 'DisplayName', '时钟量化误差');
    xlabel('归一化参数', 'FontSize', 10);
    ylabel('归一化误差', 'FontSize', 10);
    title('结论2：时钟频率影响', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
    legend('Location', 'best');
    
    subplot(3, 3, 3);
    % 提取RC非理想因素数据（选择零点偏移数据，使用单独表格）
    rc_data = data_rc_offset(data_rc_offset.V_offset_mV > 0, :);
    if ~isempty(rc_data)
        T1_norm = (rc_data.T1_ms - min(rc_data.T1_ms)) / (max(rc_data.T1_ms) - min(rc_data.T1_ms));
        error_rc_norm = abs(rc_data.Error_mV) / max(abs(rc_data.Error_mV));
        plot(T1_norm, error_rc_norm, 'b-', 'LineWidth', 2, 'DisplayName', 'RC非理想因素');
        xlabel('归一化参数', 'FontSize', 10);
        ylabel('归一化误差', 'FontSize', 10);
        title('结论3：积分时间影响', 'FontSize', 11, 'FontWeight', 'bold');
        grid on;
        legend('Location', 'best');
    end
    
    subplot(3, 3, 4);
    integer_mask = data_noise.Is_Integer_Multiple == 1;
    plot(data_noise.T1_T50Hz_Ratio(integer_mask), ...
        data_noise.Error_Mean_mV(integer_mask), 'go', 'MarkerSize', 8, ...
        'LineWidth', 2, 'DisplayName', '整数倍周期');
    hold on;
    plot(data_noise.T1_T50Hz_Ratio(~integer_mask), ...
        data_noise.Error_Mean_mV(~integer_mask), 'ro', 'MarkerSize', 8, ...
        'LineWidth', 2, 'DisplayName', '非整数倍周期');
    xlabel('T_1 / T_{50Hz}', 'FontSize', 10);
    ylabel('测量误差 (mV)', 'FontSize', 10);
    title('结论4：工频干扰抑制', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
    legend('Location', 'best');
    
    % 子图5-8：关键参数对比
    subplot(3, 3, 5);
    bar([1, 2], [mean(abs(data_vref.Relative_Error_Percent)), ...
        mean(data_clock.Relative_Error_Percent)], ...
        'FaceColor', [0.3 0.6 0.9]);
    set(gca, 'XTickLabel', {'基准电压偏差', '时钟量化误差'});
    ylabel('平均相对误差 (%)', 'FontSize', 10);
    title('误差对比', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
    
    subplot(3, 3, 6);
    % 显示不同非理想因素的最大误差（使用单独表格）
    try
        rc_offset_max = max(abs(data_rc_offset.Error_mV));
        rc_bias_max = max(abs(data_rc_bias.Error_mV));
        rc_leak_max = max(abs(data_rc_leak.Error_mV));
        max_errors = [rc_offset_max, rc_bias_max, rc_leak_max];
        bar(max_errors, 'FaceColor', [0.7 0.5 0.3]);
        set(gca, 'XTickLabel', {'零点偏移', '偏置电压', '电容漏电'});
        ylabel('最大误差 (mV)', 'FontSize', 10);
        title('非理想因素误差对比', 'FontSize', 11, 'FontWeight', 'bold');
        grid on;
    catch
        % 如果读取失败，跳过这个子图
        text(0.5, 0.5, '数据不可用', 'HorizontalAlignment', 'center');
        title('非理想因素误差对比', 'FontSize', 11, 'FontWeight', 'bold');
    end
    
    subplot(3, 3, 7);
    % 工频干扰抑制效果对比
    error_int = mean(data_noise.Error_Mean_mV(integer_mask));
    error_nonint = mean(data_noise.Error_Mean_mV(~integer_mask));
    bar([1, 2], [error_int, error_nonint], 'FaceColor', [0.5 0.7 0.5]);
    set(gca, 'XTickLabel', {'整数倍周期', '非整数倍周期'});
    ylabel('平均误差 (mV)', 'FontSize', 10);
    title('工频干扰抑制对比', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
    
    subplot(3, 3, 8);
    % 分辨率对比（时钟频率）
    selected_freqs = [0.1, 0.5, 1, 5, 10];
    resolutions = zeros(size(selected_freqs));
    for i = 1:length(selected_freqs)
        idx = find(abs(data_clock.Clock_Frequency_MHz - selected_freqs(i)) < 0.1, 1);
        if ~isempty(idx)
            resolutions(i) = data_clock.Resolution_mV(idx);
        end
    end
    bar(selected_freqs, resolutions, 'FaceColor', [0.8 0.4 0.6]);
    xlabel('时钟频率 (MHz)', 'FontSize', 10);
    ylabel('测量分辨率 (mV)', 'FontSize', 10);
    title('不同时钟频率下的分辨率', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
    
    subplot(3, 3, 9);
    % 综合结论总结
    axis off;
    text(0.1, 0.9, '仿真结论总结', 'FontSize', 14, 'FontWeight', 'bold');
    text(0.1, 0.75, '1. 基准电压稳定性越高，测量精度越高', 'FontSize', 11);
    text(0.1, 0.6, '2. 提高时钟频率可降低量化误差，提高分辨率', 'FontSize', 11);
    text(0.1, 0.45, '3. 积分时间越长，非理想因素影响越明显', 'FontSize', 11);
    text(0.1, 0.3, '4. T_1为工频周期整数倍时，干扰完全抵消', 'FontSize', 11);
    
    sgtitle('双积分式电压表仿真结果综合对比', 'FontSize', 16, 'FontWeight', 'bold');
    
    % 保存图片
    fig_dir = 'figures';
    if ~exist(fig_dir, 'dir')
        [status, msg] = mkdir(fig_dir);
        if status == 0
            error('无法创建目录 %s: %s', fig_dir, msg);
        end
    end
    fig_path = fullfile(fig_dir, 'comprehensive_results.png');
    saveas(gcf, fig_path);
    fprintf('综合图表已保存到 %s\n', fig_path);
end

