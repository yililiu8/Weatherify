//
//  DesignableProgessView.swift
//  Weatherify
//
//  Created by Yili Liu on 3/25/21.
//

import Foundation
import UIKit

@IBDesignable
class DesignableProgessView: UIView {
    @IBInspectable var color: UIColor = .gray {
            didSet { setNeedsDisplay() }
        }
    @IBInspectable var gradientColor: UIColor = UIColor.init(red: 30.0/255.0, green: 215.0/255.0, blue: 96.0/255.0, alpha: 1.0) {
            didSet { setNeedsDisplay() }
        }

        var progress: CGFloat = 0 {
            didSet { setNeedsDisplay() }
        }

        private let progressLayer = CALayer()
        private let gradientLayer = CAGradientLayer()
        private let backgroundMask = CAShapeLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupLayers()
            createAnimation()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupLayers()
            createAnimation()
        }

        private func setupLayers() {
            layer.addSublayer(gradientLayer)

            gradientLayer.mask = progressLayer
            gradientLayer.locations = [0.35, 0.5, 0.65]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        }

        private func createAnimation() {
            let flowAnimation = CABasicAnimation(keyPath: "locations")
            flowAnimation.fromValue = [-0.3, -0.15, 0]
            flowAnimation.toValue = [1, 1.15, 1.3]

            flowAnimation.isRemovedOnCompletion = false
            flowAnimation.repeatCount = Float.infinity
            flowAnimation.duration = 1.25

            gradientLayer.add(flowAnimation, forKey: "flowAnimation")
        }

        override func draw(_ rect: CGRect) {
            backgroundMask.path = UIBezierPath(roundedRect: rect, cornerRadius: rect.height * 0.50).cgPath
            layer.mask = backgroundMask

            let progressRect = CGRect(origin: .zero, size: CGSize(width: rect.width * progress, height: rect.height))

            progressLayer.frame = progressRect
            progressLayer.backgroundColor = UIColor.black.cgColor

            gradientLayer.frame = rect
            gradientLayer.colors = [color.cgColor, gradientColor.cgColor, color.cgColor]
            gradientLayer.endPoint = CGPoint(x: progress, y: 0.5)
        }
}
