import { BrainData, BrainWaves, calculateFatigue, evaluateFlowState } from '../model/BrainData';

/**
 * 🌟 ZKBrain 鸿蒙原生 ArkUI 脑机交互控制台
 * 技术支持：熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)
 */
@Entry
@Component
struct Index {
  @State isConnected: boolean = false;
  @State connectionStateText: string = "未连接";
  @State attention: number = 0;
  @State meditation: number = 0;
  @State fatigueIndex: number = 0;
  @State flowState: string = "待命中";

  @State waves: BrainWaves = {
    delta: 12000,
    theta: 8500,
    lowAlpha: 14200,
    highAlpha: 19800,
    lowBeta: 22000,
    highBeta: 11000,
    lowGamma: 4500,
    middleGamma: 2100
  };

  private wavePoints: number[] = [];
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private timerId: number = -1;

  aboutToAppear(): void {
    // 启动模拟波形渲染时钟
    this.timerId = setInterval(() => {
      if (this.isConnected) {
        // 动态模拟 1Hz 脑电指标微动
        this.attention = Math.floor(60 + Math.random() * 30);
        this.meditation = Math.floor(50 + Math.random() * 35);
        this.fatigueIndex = calculateFatigue(this.waves);
        this.flowState = evaluateFlowState(this.attention, this.meditation, this.fatigueIndex);

        // 模拟 512Hz 示波器点位推进
        const val = (Math.random() - 0.5) * 80;
        if (this.wavePoints.length >= 200) {
          this.wavePoints.shift();
        }
        this.wavePoints.push(val);
        this.drawWaveform();
      }
    }, 50);
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
  }

  drawWaveform(): void {
    const ctx = this.canvasContext;
    const w = ctx.width;
    const h = ctx.height;
    const midY = h / 2;

    ctx.clearRect(0, 0, w, h);

    // 绘制中轴基线
    ctx.strokeStyle = "#334155";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, midY);
    ctx.lineTo(w, midY);
    ctx.stroke();

    if (this.wavePoints.length < 2) return;

    ctx.strokeStyle = "#00E5FF";
    ctx.lineWidth = 2;
    ctx.beginPath();

    const stepX = w / (this.wavePoints.length - 1);
    this.wavePoints.forEach((val, i) => {
      const x = i * stepX;
      const y = Math.max(0, Math.min(h, midY - (val / 100) * (h / 2.5)));
      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    });
    ctx.stroke();
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // 顶部导航标题
        Row() {
          Text("ZKBrain 鸿蒙脑机交互看板")
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width('100%')
        .padding({ top: 20, bottom: 8 })

        // 1. 链路控制卡片
        Row() {
          Row({ space: 8 }) {
            Circle()
              .width(12)
              .height(12)
              .fill(this.isConnected ? "#22C55E" : "#EF4444")
            Text(`链路状态: ${this.connectionStateText}`)
              .fontSize(15)
              .fontColor(Color.White)
          }

          Button(this.isConnected ? "断开设备" : "⚡ 扫描并连接")
            .backgroundColor(this.isConnected ? "#DC2626" : "#2563EB")
            .fontSize(14)
            .borderRadius(8)
            .onClick(() => {
              this.isConnected = !this.isConnected;
              this.connectionStateText = this.isConnected ? "已就绪 (CONNECTED)" : "未连接";
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor("#1E293B")
        .borderRadius(12)
        .justifyContent(FlexAlign.SpaceBetween)

        // 2. 专注与放松核心认知指标
        Column({ space: 12 }) {
          Text("核心认知指标 (1Hz eSense)")
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)

          // 专注度
          Column({ space: 4 }) {
            Row() {
              Text("专注度 (Attention)").fontSize(14).fontColor("#94A3B8")
              Text(`${this.attention} / 100`).fontSize(14).fontColor("#38BDF8").fontWeight(FontWeight.Bold)
            }.width('100%').justifyContent(FlexAlign.SpaceBetween)

            Progress({ value: this.attention, total: 100, type: ProgressType.Linear })
              .color("#38BDF8")
              .height(8)
              .width('100%')
          }

          // 放松度
          Column({ space: 4 }) {
            Row() {
              Text("放松度 (Meditation)").fontSize(14).fontColor("#94A3B8")
              Text(`${this.meditation} / 100`).fontSize(14).fontColor("#4ADE80").fontWeight(FontWeight.Bold)
            }.width('100%').justifyContent(FlexAlign.SpaceBetween)

            Progress({ value: this.meditation, total: 100, type: ProgressType.Linear })
              .color("#4ADE80")
              .height(8)
              .width('100%')
          }

          Row() {
            Text(`心流状态: ${this.flowState}`).fontSize(13).fontColor("#FBBF24")
            Text(`疲劳指数: ${this.fatigueIndex}%`)
              .fontSize(13)
              .fontColor(this.fatigueIndex >= 60 ? "#F87171" : "#94A3B8")
          }.width('100%').justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(16)
        .backgroundColor("#1E293B")
        .borderRadius(12)

        // 3. 512Hz 实时示波器
        Column() {
          Row() {
            Text("512Hz 实时示波器 (Raw EEG, μV)").fontSize(13).fontColor("#38BDF8")
            Text("512 Hz").fontSize(12).fontColor("#4ADE80")
          }.width('100%').justifyContent(FlexAlign.SpaceBetween).padding({ bottom: 8 })

          Canvas(this.canvasContext)
            .width('100%')
            .height(110)
            .backgroundColor("#0F172A")
            .borderRadius(8)
        }
        .width('100%')
        .padding(12)
        .backgroundColor("#1E293B")
        .borderRadius(12)

        // 4. 8 频段功率谱能量
        Column({ space: 8 }) {
          Text("脑波 8 频段能量分布 (EEG Power Spectrum)")
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)

          this.buildPowerRow("Delta (0.5-2.75Hz 深度睡眠)", this.waves.delta, "#818CF8")
          this.buildPowerRow("Theta (3.5-6.75Hz 冥想/创意)", this.waves.theta, "#38BDF8")
          this.buildPowerRow("Low Alpha (7.5-9.25Hz 放松闭眼)", this.waves.lowAlpha, "#34D399")
          this.buildPowerRow("High Alpha (10-11.75Hz 静心心流)", this.waves.highAlpha, "#4ADE80")
          this.buildPowerRow("Low Beta (13-16.75Hz 轻度专注)", this.waves.lowBeta, "#FBBF24")
          this.buildPowerRow("High Beta (17-29.75Hz 紧张计算)", this.waves.highBeta, "#FB923C")
          this.buildPowerRow("Low Gamma (31-39.75Hz 认知加工)", this.waves.lowGamma, "#F43F5E")
          this.buildPowerRow("Middle Gamma (41-49.75Hz 多感官整合)", this.waves.middleGamma, "#E11D48")
        }
        .width('100%')
        .padding(16)
        .backgroundColor("#1E293B")
        .borderRadius(12)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor("#0F172A")
  }

  @Builder
  buildPowerRow(title: string, value: number, barColor: string) {
    Column({ space: 2 }) {
      Row() {
        Text(title).fontSize(12).fontColor("#CBD5E1")
        Text(`${value}`).fontSize(12).fontColor(barColor).fontWeight(FontWeight.Bold)
      }.width('100%').justifyContent(FlexAlign.SpaceBetween)

      Progress({ value: Math.min(50000, value), total: 50000, type: ProgressType.Linear })
        .color(barColor)
        .height(4)
        .width('100%')
    }
    .width('100%')
    .margin({ top: 2, bottom: 2 })
  }
}
