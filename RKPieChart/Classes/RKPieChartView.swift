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

public class RKPieChartView: UIView {
    
    /// background color of the pie
    public var circleColor: UIColor = .white {
        didSet {
            setNeedsLayout()
        }
    }
    
    
    /// width of the each item
    public var arcWidth: CGFloat = 75 {
        didSet {
            setNeedsLayout()
        }
    }
    
    
    /// add intensity to item or not
    public var isIntensityActivated: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// show the titles of the item or not
    public var isTitleViewHidden: Bool = false {
        didSet {
            if !isTitleViewHidden {
                titlesView?.removeFromSuperview()
                updateConstraints()
            }
        }
    }
    
    /// line cap style. ex: butt, round, square
    public var style: CGLineCap = .butt {
        didSet {
            if (items.count != 1 && style != .butt) {
                assertionFailure("Number of items should be equal to 1 to update style")
                style = .butt
            }
            setNeedsLayout()
        }
    }
    
    
    /// animate each item or not
    public var isAnimationActivated: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    private var items: [RKPieChartItem] = [RKPieChartItem]()
    private var shapeLayers: [CAShapeLayer] = []
    private var pathes: [UIBezierPath] = []
    private var selectedItem: RKPieChartItem? {
        didSet {
//            configureColors()
        }
    }
    private var titlesView: UIStackView?
    private var totalRatio: CGFloat = 0
    private let itemHeight: CGFloat = 10.0
    var centerTitle: String?
    private var centerLabel: UILabel?
    
    private var currentTime = CACurrentMediaTime()
    
    override public func draw(_ rect: CGRect) {
        
        // Center of the view
        let center = calculateCenter()
        
        // Radius of the view
        let radius = calculateRadius()
        
        let arcWidth: CGFloat = self.arcWidth
        
        let circlePath = UIBezierPath(arcCenter: center,
                                      radius: radius/2 - arcWidth/2,
                                      startAngle: 0,
                                      endAngle: 2 * π,
                                      clockwise: true)
        
        // draw circle path
        circlePath.lineWidth = arcWidth
        circleColor.setStroke()
        circlePath.lineCapStyle = style
        circlePath.stroke()
        
        if (items.count > 0) {
            drawCircle()
        }
    }
    
    
    /// Init PKPieChartView
    ///
    /// - Parameters:
    ///   - items: pie chart items to be displayed
    ///   - centerTitle: add title to the center of the pie chart
    convenience public init(items: [RKPieChartItem], centerTitle: String? = nil) {
        self.init()
        self.items = items
        self.centerTitle = centerTitle
        calculateAngles()
        backgroundColor = .clear
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if !isTitleViewHidden {
            showChildTitles()
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        
        guard let point = touch?.location(in: self) else { return }
        
//        self.selectedItem = nil
//        pathes.enumerated().forEach { (index, path) in
//            if path.contains(point) {
//
//
//                let item = items[index]
//
//                if let selectedItem = self.selectedItem {
//                    if selectedItem.identifier == item.identifier {
//                        self.selectedItem = nil
//                    } else {
//                        self.selectedItem = item
//                    }
//                } else {
//                    self.selectedItem = item
//                }
//            }
//        }
//
//
//        return
        guard let sublayers = self.layer.sublayers else { return }
        
        selectedItem = nil
        
        for layer in sublayers {

            
            guard let shapeLayer = layer as? CAShapeLayer else {continue}
//            guard let tapped = shapeLayer.hitTest(point) else {continue}
            guard let path = shapeLayer.path else {continue}
            guard path.contains(point) else {continue}
            guard let index = shapeLayers.index(of: shapeLayer) else {return}
            let item = items[index]
            
            if let selectedItem = self.selectedItem {
                if selectedItem.identifier == item.identifier {
                    self.selectedItem = nil
                } else {
                    self.selectedItem = item
                }
            } else {
                self.selectedItem = item
            }
        }
        
        
        configureColors()

    }
    
    func configureColors() {
        if let selectedItem = selectedItem {
            items.enumerated().forEach { [unowned self] (index, item) in
                let shapeLayer = self.shapeLayers[index]

                if item.identifier == selectedItem.identifier {
                    shapeLayer.opacity = 1
                } else {
                    shapeLayer.opacity = 0.2
                }
            }
        } else {
            items.enumerated().forEach { [unowned self] (index, item) in
                let shapeLayer = self.shapeLayers[index]
                shapeLayer.opacity = 1
            }
        }
    }
    
    private func drawCircle(){
        shapeLayers.forEach { (layer) in
            layer.removeFromSuperlayer()
        }
        shapeLayers = []
        
        
        items.enumerated().forEach { (index, item) in
            // Center of the view
            let center = calculateCenter()
            
            // Radius of the view
            let radius: CGFloat = calculateRadius()
            let arcWidth: CGFloat = self.arcWidth
            let circlePath = UIBezierPath(arcCenter: center,
                                          radius: radius/2 - arcWidth/2,
                                          startAngle: item.startAngle!,
                                          endAngle: item.endAngle!,
                                          clockwise: true)
            
            circlePath.lineCapStyle = style
            
            if(!isAnimationActivated) {
                // Draw circle path
                circlePath.lineWidth = arcWidth
                circlePath.lineCapStyle = .round
                circlePath.lineJoinStyle = .round
                item.color.setStroke()
                circlePath.stroke()
                
                pathes.append(circlePath)
            }
            else {
                let shapeLayer: CAShapeLayer = CAShapeLayer()
                shapeLayer.path = circlePath.cgPath
                shapeLayer.strokeColor = item.color.cgColor
                shapeLayer.lineWidth = arcWidth
                shapeLayer.fillColor = UIColor.clear.cgColor
                shapeLayer.lineCap = kCALineCapRound
                shapeLayer.lineJoin = kCALineJoinRound
//                shapeLayer.bounds = shapeLayer.path!.boundingBoxOfPath
                
//                shapeLayer.bounds = (shapeLayer.path?.boundingBox)!

                
                layer.addSublayer(shapeLayer)
                shapeLayers.append(shapeLayer)
                //                let animation = CABasicAnimation(keyPath: "strokeEnd")
                //                animation.duration = 0.5
                //                animation.fromValue = 0.0
                //                animation.toValue = 1.0
                //                shapeLayer.add(animation, forKey: "strokeEnd")
            }
            
            if (isIntensityActivated) {
                let deepPath = UIBezierPath(arcCenter: center,
                                            radius: radius/2 - arcWidth - 5,
                                            startAngle: item.startAngle!,
                                            endAngle: item.endAngle!,
                                            clockwise: true)
                deepPath.lineWidth = 10
                item.color.light.setStroke()
                deepPath.lineCapStyle = style
                deepPath.stroke()
            }
            if(centerLabel == nil && centerTitle != nil) {
                centerLabel = UILabel(frame: .zero)
                centerLabel?.translatesAutoresizingMaskIntoConstraints = false
                centerLabel?.font = UIFont(name: "HelveticaNeue", size: 14.0)
                centerLabel?.minimumScaleFactor = 0.7
                centerLabel?.numberOfLines = 2
                centerLabel?.textAlignment = .center
                centerLabel?.text = centerTitle
                self.addSubview(centerLabel!)
                
                centerLabel?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
                centerLabel?.widthAnchor.constraint(equalToConstant: radius/2 - arcWidth/2).isActive = true
                
                if (isTitleViewHidden) {
                    centerLabel?.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                }
                else {
                    centerLabel?.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -(CGFloat(items.count) * itemHeight)).isActive = true
                }
            }
        }
    }
    
    
    /// calculate each item's angle to present pie chart
    //    private func calculateAngles() {
    //        totalRatio = items.map({ $0.ratio }).reduce(0, { $0 + $1 })
    //        for (index, item) in items.enumerated() {
    //            let degreeOffset = 6
    //
    //            item.startAngle = index == 0 ? 3 * π / 2 : items[index - 1].endAngle!// + CGFloat(2).degreesToRadians
    //            item.startAngle = item.startAngle! + CGFloat(index == 0 ? 0 : degreeOffset * 2).degreesToRadians
    //            if items.count == 1 {
    //                totalRatio = item.ratio
    //            }
    //            item.endAngle = item.startAngle! + (CGFloat( (360 - (0 * items.count)) ) * item.ratio / totalRatio).degreesToRadians
    //            item.endAngle = item.endAngle! - CGFloat(degreeOffset * 2).degreesToRadians
    //            //            if item.endAngle! > 2 * π {
    //            //                item.endAngle = item.endAngle! - 2 * π
    //            //            }
    //
    //            item.endAngle = max(item.startAngle!, item.endAngle!)
    //        }
    //    }
    
    
    private func calculateAngles() {
        totalRatio = items.map({ $0.ratio }).reduce(0, { $0 + $1 })
        
        for (index, item) in items.enumerated() {
//            let radius: CGFloat = 150.0 - arcWidth
//            let digreesInPixel: CGFloat = radius/90
//            let degreeOffset = digreesInPixel * 5
            
            let degreeOffset: CGFloat = 16
            
            item.startAngle = index == 0 ? 3 * π / 2 : items[index - 1].endAngle!
            item.startAngle = item.startAngle! + CGFloat(index == 0 ? 2 : degreeOffset).degreesToRadians
            
            item.endAngle = item.startAngle! + (CGFloat( (360 - (degreeOffset * CGFloat(items.count))) ) * item.ratio / totalRatio).degreesToRadians
            //            if item.endAngle! > 2 * π {
            //                item.endAngle = item.endAngle! - 2 * π
            //            }
            
            item.endAngle = max(item.startAngle!, item.endAngle!)
        }
    }
    
    
    /// show each item's title
    private func showChildTitles() {
        if (titlesView == nil) {
            titlesView = UIStackView(frame: CGRect(x: 0, y: bounds.height - (CGFloat(2 * items.count) * itemHeight), width: bounds.width, height: CGFloat(2 * items.count) * itemHeight))
            titlesView?.backgroundColor = .gray
            titlesView?.axis = .vertical
            titlesView?.distribution  = .fillEqually
            titlesView?.alignment = .fill
            self.addSubview(titlesView!)
            
            items.forEach({ (item) in
                let view = RKChartTitleView(item: item)
                titlesView?.addArrangedSubview(view)
            })
        }
    }
    
    /// calculate center of the graph
    ///
    /// - Returns: point of the center
    private func calculateCenter() -> CGPoint {
        if isTitleViewHidden {
            return CGPoint(x:bounds.width/2, y: bounds.height/2)
        }
        else {
            return CGPoint(x:bounds.width/2, y: bounds.height/2 - CGFloat(items.count) * itemHeight)
        }
    }
    
    /// calculate radius of the graph
    ///
    /// - Returns: value of the radius
    private func calculateRadius() -> CGFloat {
        if isTitleViewHidden {
            return min(bounds.width, bounds.height)
        }
        else {
            return min(bounds.width - CGFloat(items.count) * 2 * itemHeight, bounds.height - CGFloat(items.count) * 2 * itemHeight)
        }
    }
}
