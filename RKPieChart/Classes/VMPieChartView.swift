//
//  RKPieChart.swift
//  Pods
//
//  Created by Ivanov Developer on 31/08/2017.
//
//

import CoreGraphics

let π: CGFloat = CGFloat(Double.pi)

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
        
        items.enumerated().forEach { (index, item) in
            let center = calculateCenter()
            let radius: CGFloat = calculateRadius()
            let arcWidth: CGFloat = self.arcWidth
            
            let circlePath = UIBezierPath(arcCenter: center,
                                          radius: radius/2 - arcWidth/2,
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
            
            let tapPath = circlePath.cgPath.copy(strokingWithWidth: circlePath.lineWidth, lineCap: circlePath.lineCapStyle, lineJoin: circlePath.lineJoinStyle, miterLimit: circlePath.miterLimit)
            
            let shape = Shape.init(path: circlePath, color: item.color, tapPath: UIBezierPath.init(cgPath: tapPath), index: index)
            
            shapes.append(shape)
        }
    }
    
    private func calculateAngles() {
        totalRatio = items.map({ $0.ratio }).reduce(0, { $0 + $1 })
        
        for (index, item) in items.enumerated() {
            let degreeOffset: CGFloat = 15
            
            item.startAngle = index == 0 ? 3 * π / 2 : items[index - 1].endAngle!
            item.startAngle = item.startAngle! + CGFloat(index == 0 ? 2 : degreeOffset).degreesToRadians
            
            item.endAngle = item.startAngle! + (CGFloat( (360 - (degreeOffset * CGFloat(items.count))) ) * item.ratio / totalRatio).degreesToRadians
            item.endAngle = max(item.startAngle!, item.endAngle!)
        }
    }
    
    /// calculate center of the graph
    ///
    /// - Returns: point of the center
    private func calculateCenter() -> CGPoint {
        return CGPoint(x:bounds.width/2, y: bounds.height/2)
    }
    
    /// calculate radius of the graph
    ///
    /// - Returns: value of the radius
    private func calculateRadius() -> CGFloat {
        return min(bounds.width, bounds.height)
    }
}
