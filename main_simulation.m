%MAIN_SIMULATION 双积分式电压表仿真主脚本
%   协调所有仿真模块，按顺序执行并生成综合报告
%
%   使用方法：
%       直接运行此脚本：main_simulation
%
%   输出：
%       - 四个Excel结果表格
%       - 所有仿真图表（保存在figures/目录）
%       - 综合对比图表

clear;
close all;
clc;

fprintf('========================================\n');
fprintf('双积分式电压表仿真系统\n');
fprintf('Dual-Slope DVM Simulation System\n');
fprintf('========================================\n\n');

% 记录开始时间
tic;

% 创建输出目录
fig_dir = 'figures';
if ~exist(fig_dir, 'dir')
    [status, msg] = mkdir(fig_dir);
    if status == 0
        error('无法创建输出目录 %s: %s', fig_dir, msg);
    end
    fprintf('已创建输出目录: %s/\n', fig_dir);
end

%% 仿真模块1：基准电压偏差影响
fprintf('\n【模块1】基准电压偏差对测量结果的影响\n');
fprintf('----------------------------------------\n');
try
    results_vref = simulate_vref_error();
    fprintf('✓ 模块1完成\n');
catch ME
    fprintf('✗ 模块1失败: %s\n', ME.message);
    rethrow(ME);
end

%% 仿真模块2：时钟量化误差影响
fprintf('\n【模块2】时钟周期量化误差对测量结果的影响\n');
fprintf('----------------------------------------\n');
try
    results_clock = simulate_clock_error();
    fprintf('✓ 模块2完成\n');
catch ME
    fprintf('✗ 模块2失败: %s\n', ME.message);
    rethrow(ME);
end

%% 仿真模块3：RC非理想因素影响
fprintf('\n【模块3】积分器RC非理想因素对测量结果的影响\n');
fprintf('----------------------------------------\n');
try
    results_rc = simulate_nonideal_rc();
    fprintf('✓ 模块3完成\n');
catch ME
    fprintf('✗ 模块3失败: %s\n', ME.message);
    rethrow(ME);
end

%% 仿真模块4：工频干扰影响
fprintf('\n【模块4】工频干扰对测量结果的影响\n');
fprintf('----------------------------------------\n');
try
    results_noise = simulate_powerline_noise();
    fprintf('✓ 模块4完成\n');
catch ME
    fprintf('✗ 模块4失败: %s\n', ME.message);
    rethrow(ME);
end

%% 综合可视化已移除（每个子图单独生成）
% 如需生成综合对比图表，可单独运行 plot_results()

%% 生成综合报告
fprintf('\n【综合报告】生成仿真报告\n');
fprintf('----------------------------------------\n');

% 计算总耗时
elapsed_time = toc;

% 生成文本报告
report_file = 'simulation_report.txt';
fid = fopen(report_file, 'w');
if fid ~= -1
    fprintf(fid, '========================================\n');
    fprintf(fid, '双积分式电压表仿真报告\n');
    fprintf(fid, 'Dual-Slope DVM Simulation Report\n');
    fprintf(fid, '========================================\n\n');
    
    fprintf(fid, '仿真时间: %s\n', datestr(now));
    fprintf(fid, '总耗时: %.2f 秒\n\n', elapsed_time);
    
    fprintf(fid, '----------------------------------------\n');
    fprintf(fid, '仿真模块执行情况\n');
    fprintf(fid, '----------------------------------------\n');
    fprintf(fid, '✓ 模块1: 基准电压偏差影响仿真\n');
    fprintf(fid, '✓ 模块2: 时钟量化误差影响仿真\n');
    fprintf(fid, '✓ 模块3: RC非理想因素影响仿真\n');
    fprintf(fid, '✓ 模块4: 工频干扰影响仿真\n\n');
    
    fprintf(fid, '----------------------------------------\n');
    fprintf(fid, '输出文件\n');
    fprintf(fid, '----------------------------------------\n');
    fprintf(fid, '结果表格:\n');
    fprintf(fid, '  - results_vref_error.xlsx\n');
    fprintf(fid, '  - results_clock_error.xlsx\n');
    fprintf(fid, '  - results_nonideal_rc.xlsx\n');
    fprintf(fid, '  - results_nonideal_rc_offset.xlsx\n');
    fprintf(fid, '  - results_nonideal_rc_bias.xlsx\n');
    fprintf(fid, '  - results_nonideal_rc_leak.xlsx\n');
    fprintf(fid, '  - results_powerline_noise.xlsx\n\n');
    
    fprintf(fid, '图表文件 (figures/):\n');
    fprintf(fid, '  结论1 (4张图): vref_error_vs_deviation.png, vref_relative_error.png,\n');
    fprintf(fid, '                 vref_stability_vs_accuracy.png, vref_linear_relationship.png\n');
    fprintf(fid, '  结论2 (6张图): clock_freq_vs_quantization_error.png, clock_period_vs_quantization_error.png,\n');
    fprintf(fid, '                 clock_freq_vs_resolution.png, clock_period_vs_resolution.png,\n');
    fprintf(fid, '                 clock_freq_vs_relative_error.png, clock_resolution_comparison.png\n');
    fprintf(fid, '  结论3 (6张图): rc_offset_error.png, rc_bias_error.png, rc_leak_error.png,\n');
    fprintf(fid, '                 rc_combined_error.png, rc_error_growth.png, rc_error_slope.png\n');
    fprintf(fid, '  结论4 (6张图): powerline_error_vs_ratio.png, powerline_rejection_ratio.png,\n');
    fprintf(fid, '                 powerline_time_domain.png, powerline_error_range.png,\n');
    fprintf(fid, '                 powerline_spectrum.png, powerline_comparison.png\n\n');
    
    fprintf(fid, '----------------------------------------\n');
    fprintf(fid, '仿真结论\n');
    fprintf(fid, '----------------------------------------\n');
    fprintf(fid, '1. 基准电压的稳定性显著影响双积分式电压表的测量精度，\n');
    fprintf(fid, '   且稳定性越高双积分式电压表的测量精度越高\n\n');
    fprintf(fid, '2. 在积分时间T_1一定的条件下，提高时钟频率减小T_{clk}\n');
    fprintf(fid, '   有利于降低量化误差，提高测量分辨率\n\n');
    fprintf(fid, '3. 如果积分器的RC处于非理想状态，积分时间越长对于\n');
    fprintf(fid, '   测试结果的影响更明显\n\n');
    fprintf(fid, '4. 当积分时间T_1取工频周期的整数倍时，工频干扰被完全抵消\n\n');
    
    fprintf(fid, '========================================\n');
    fprintf(fid, '报告结束\n');
    fprintf(fid, '========================================\n');
    
    fclose(fid);
    fprintf('综合报告已保存到: %s\n', report_file);
else
    warning('无法创建报告文件');
end

%% 完成提示
fprintf('\n========================================\n');
fprintf('所有仿真模块执行完成！\n');
fprintf('========================================\n');
fprintf('总耗时: %.2f 秒\n', elapsed_time);
fprintf('\n输出文件位置:\n');
fprintf('  - 结果表格: 当前目录\n');
fprintf('  - 图表文件: figures/ 目录\n');
fprintf('  - 综合报告: %s\n', report_file);
fprintf('\n请查看生成的Excel表格和PNG图表以分析结果。\n\n');

