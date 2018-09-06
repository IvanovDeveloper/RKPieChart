//
//  RKPieChart.swift
//  Pods
//
//  Created by Ivanov Developer on 31/08/2017.
//
//

import CoreGraphics

let π: CGFloat = .pi

private enum LineCapStyle: Int {
    
    case butt = 0
    case round
    case style
    
    var description: String {
        get { return String(describing: self) }
    }
}

public struct Shape: Equatable {
    let path: UIBezierPath
    let color: UIColor
    let tapPath: UIBezierPath
    let index: Int
}

public class VMPieChartView: UIView {
    
    /// width of the each item
    public var arcWidth: CGFloat = 75 {
        didSet {
            setNeedsLayout()
        }
    }
    
    private var items: [VMPieChartItem] = [VMPieChartItem]()
    public var shapes: [Shape] = []
    public var selectedShape: Shape? {
        didSet {
            didSelectedIndex?(selectedIndex)
        }
    }
    public var didSelectedIndex: ((Int?) -> Void)?
    public var selectedIndex: Int? {
        return selectedShape?.index
    }
    
    
    private var totalRatio: CGFloat = 0
    private let itemHeight: CGFloat = 10.0
    
    // MARK: - Life Cycle
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .clear
    }
    
    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = .clear
        
    }
    
    /// Init PKPieChartView
    ///
    /// - Parameters:
    ///   - items: pie chart items to be displayed
    ///   - centerTitle: add title to the center of the pie chart
    convenience public init(items: [VMPieChartItem], centerTitle: String? = nil) {
        self.init()
        self.items = items
        calculateAngles()
        backgroundColor = .clear
    }
    
    public func configure(items: [VMPieChartItem], centerTitle: String? = nil) {
        self.items = items
        calculateAngles()
        setNeedsDisplay()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        
        guard let point = touch?.location(in: self) else { return }

        var tappedShape: Shape?
        shapes.enumerated().forEach { (index, shape) in
            if shape.tapPath.contains(point) {
                tappedShape = shape
            }
        }
        selectedShape = tappedShape
        self.setNeedsDisplay()
    }
    
    override public func draw(_ rect: CGRect) {
        if (items.count > 0) {
            drawCircle()
        }
    }
    
    private func drawCircle(){
        shapes.removeAll()
        clearText()
        let center = calculateCenter(of: bounds)
        let radius = calculateRadius(fitIn: bounds)
        let arcWidth = self.arcWidth
        items.enumerated().forEach { (index, item) in
            let circlePath = UIBezierPath(arcCenter: center,
                                          radius: radius - arcWidth/2,
                                          startAngle: item.startAngle!,
                                          endAngle: item.endAngle!,
                                          clockwise: true)
            
            circlePath.lineWidth = arcWidth
            circlePath.lineCapStyle = .round
            circlePath.lineJoinStyle = .round
            
            if let shape = selectedShape {
                if shape.index == index {
                    item.color.setStroke()
                } else {
                    item.color.alpha20.setStroke()
                }
            } else {
                item.color.setStroke()
                
            }
            circlePath.stroke()
            
            // MARK: - kludge for inscriptions
            if abs((item.endAngle! - item.startAngle!).truncatingRemainder(dividingBy: (2 * .pi)) ) > (.pi / 45) {
                let labelAngle = item.endAngle! - (.pi / 108)
                let textHeight: CGFloat = 9
                let textWidth: CGFloat = 12
                let xPosition = center.x + cos(labelAngle) * (radius - arcWidth / 2) - textWidth / 2
                let yPosition = center.y + sin(labelAngle) * (radius - arcWidth / 2) - textWidth / 2
                let boundingRect = CGRect(x: xPosition, y: yPosition, width: textWidth, height: textHeight)
                let textLayer = getTextLayer(text: item.title ?? "", bounding: boundingRect)
                layer.addSublayer(textLayer)
            }

            let tapPath = circlePath.cgPath.copy(strokingWithWidth: circlePath.lineWidth, lineCap: circlePath.lineCapStyle, lineJoin: circlePath.lineJoinStyle, miterLimit: circlePath.miterLimit)
            
            let shape = Shape.init(path: circlePath, color: item.color, tapPath: UIBezierPath.init(cgPath: tapPath), index: index)
            
            shapes.append(shape)
        }
    }
    
    private func clearText() {
        layer.sublayers?.forEach({ (sublayer) in
            if sublayer is CATextLayer {
                sublayer.removeFromSuperlayer()
            }
        })
    }

    private func getTextLayer(text: String, bounding: CGRect) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.frame = bounding
        textLayer.foregroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        textLayer.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.font = CTFontCreateWithName("Helvetica" as CFString, 0, nil)
        textLayer.fontSize = 9
        textLayer.string = text
        textLayer.alignmentMode = kCAAlignmentCenter
        return textLayer
    }

    private func calculateAngles() {
        totalRatio = items.map({ $0.ratio }).reduce(0, { $0 + $1 })
        
        for (index, item) in items.enumerated() {
            let degreeOffset: CGFloat = 10
            
            item.startAngle = index == 0 ? 3 * π / 2 : items[index - 1].endAngle!
            item.startAngle = item.startAngle! + CGFloat(index == 0 ? 2 : degreeOffset).degreesToRadians
            
            item.endAngle = item.startAngle! + (CGFloat( (360 - (degreeOffset * CGFloat(items.count))) ) * item.ratio / totalRatio).degreesToRadians
            item.endAngle = max(item.startAngle!, item.endAngle!)
        }
    }
    
    /// calculate center of the graph
    ///
    /// - Returns: point of the center
    private func calculateCenter(of rect: CGRect) -> CGPoint {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        return center
    }
    
    /// calculate diameter of the graph
    ///
    /// - Returns: value of the diameter
    private func calculateDiameter(fitIn rect: CGRect) -> CGFloat {
        let fitDiameter = min(rect.width, rect.height)
        return fitDiameter
    }

    /// calculate radius of the graph
    ///
    /// - Returns: value of the radius
    private func calculateRadius(fitIn rect: CGRect) -> CGFloat {
        let fitRadius = calculateDiameter(fitIn: rect) / 2
        return fitRadius
    }
}
