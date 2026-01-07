function [T2, V_measured, error, V_out1] = dual_slope_dvm(V_in, V_ref, T1, f_clk, ...
    V_offset, V_bias, R_leak, C, R, noise_signal)
%DUAL_SLOPE_DVM 双积分式电压表核心函数
%   实现双积分式电压表的完整测量过程，包括非理想因素建模
%
%   输入参数:
%       V_in: 输入电压 (V)
%       V_ref: 基准电压 (V)
%       T1: 第一阶段积分时间 (s)
%       f_clk: 时钟频率 (Hz)
%       V_offset: 零点偏移电压 (V)
%       V_bias: 偏置电压 (V)
%       R_leak: 电容漏电电阻 (Ohm)，如果为inf表示无漏电
%       C: 积分电容 (F)
%       R: 积分电阻 (Ohm)
%       noise_signal: 干扰信号函数句柄或时间序列，格式: noise_signal(t)
%
%   输出参数:
%       T2: 第二阶段积分时间 (s)
%       V_measured: 测量得到的电压 (V)
%       error: 测量误差 (V)
%       V_out1: 第一阶段结束时的积分器输出电压 (V)

    % 参数检查
    if nargin < 10
        noise_signal = @(t) 0;  % 默认无干扰
    end
    if nargin < 9 || isempty(R)
        R = 100e3;  % 默认积分电阻100kΩ
    end
    if nargin < 8 || isempty(C)
        C = 1e-6;  % 默认积分电容1μF
    end
    if nargin < 7 || isempty(R_leak)
        R_leak = inf;  % 默认无漏电
    end
    if nargin < 6 || isempty(V_bias)
        V_bias = 0;  % 默认无偏置
    end
    if nargin < 5 || isempty(V_offset)
        V_offset = 0;  % 默认无零点偏移
    end
    
    % 计算时间步长（时钟周期的1/10以确保精度）
    T_clk = 1 / f_clk;
    dt = T_clk / 10;
    
    % RC时间常数
    tau = R * C;
    
    % 第一阶段积分：对输入电压积分
    t1 = 0:dt:T1;
    V_out = 0;  % 初始输出电压为0
    
    % 数值积分（欧拉法）
    for i = 1:length(t1)-1
        t_curr = t1(i);
        
        % 获取干扰信号
        if isa(noise_signal, 'function_handle')
            V_noise = noise_signal(t_curr);
        else
            % 如果是时间序列，需要插值
            V_noise = 0;
        end
        
        % 输入信号（包括干扰和偏置）
        V_input = V_in + V_noise + V_bias;
        
        % 积分器输入电流
        I_input = V_input / R;
        
        % 考虑漏电的影响
        if isfinite(R_leak)
            I_leak = V_out / R_leak;  % 漏电流
        else
            I_leak = 0;
        end
        
        % 积分器输出电压变化
        dV_out = (I_input - I_leak) * dt / C;
        V_out = V_out + dV_out;
    end
    
    V_out1 = V_out;  % 第一阶段结束时的输出电压
    
    % 第二阶段积分：对基准电压反向积分，直到回到零点
    % 目标电压是零点偏移电压（不是0）
    target_voltage = V_offset;
    
    % 计算理论T2（考虑漏电的影响）
    % 如果无漏电：V_out1 - (V_ref/R) * T2 / C = target_voltage
    % 如果有漏电，需要解微分方程
    % 简化计算：假设漏电影响较小，使用近似公式
    if isfinite(R_leak)
        % 考虑漏电的修正（一阶近似）
        tau_leak = R_leak * C;
        % 使用数值方法求解（简化：假设漏电影响线性）
        T2_theoretical = (V_out1 - target_voltage) * R * C / V_ref;
        % 漏电修正项（简化处理）
        leak_correction = T2_theoretical^2 / (2 * tau_leak);
        T2_theoretical = T2_theoretical + leak_correction;
    else
        % 无漏电情况
        T2_theoretical = (V_out1 - target_voltage) * R * C / V_ref;
    end
    
    % 考虑时钟量化：T2必须是时钟周期的整数倍
    N_clk = round(T2_theoretical / T_clk);
    if N_clk < 1
        N_clk = 1;  % 至少一个时钟周期
    end
    T2 = N_clk * T_clk;  % 量化后的T2
    
    % 计算测量结果
    V_measured = V_ref * (T2 / T1);
    
    % 计算误差
    error = V_measured - V_in;
end

