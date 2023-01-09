//
//  AlertViewController.swift
//  DesignSystem
//
//  Created by Tung Nguyen on 03/01/2023.
//

import UIKit

public enum PopupHeight {
    case fixed(CGFloat)
    case intrinsic
}

public struct PopupConfiguration {
    public var height: PopupHeight = .intrinsic
    public var cornerRadius: CGFloat = 16
    public var horizontalPadding: CGFloat = 16
    
    public init(height: PopupHeight = .intrinsic, cornerRadius: CGFloat = 16, horizontalPadding: CGFloat = 16) {
        self.height = height
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
    }
}

public class PopupViewController: UIViewController {
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .init(red: 27.0/255, green: 29.0/255, blue: 28.0/255, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let scrollView = UIScrollView()
    var contentViewController: UIViewController!
    var configuration: PopupConfiguration = .init()
    
    public init(vc: UIViewController, configuration: PopupConfiguration) {
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .custom
        self.configuration = configuration
        self.contentViewController = vc
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(contentViewController)
        containerView.addSubview(contentViewController.view)
        contentViewController.view.frame = containerView.bounds
        contentViewController.didMove(toParent: self)
        
        setupViews()
    }
    
    func setupViews() {
        view.backgroundColor = UIColor(red: 15.0/255, green: 15.0/255, blue: 15.0/255, alpha: 0.9)
        view.addSubview(containerView)
        
        containerView.layer.cornerRadius = configuration.cornerRadius
        containerView.layer.masksToBounds = true
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: configuration.horizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -configuration.horizontalPadding),
            containerView.heightAnchor.constraint(equalToConstant: calculateHeight(vc: contentViewController)),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func calculateHeight(vc: UIViewController) -> CGFloat {
        switch configuration.height {
        case .fixed(let height):
            return height
        case .intrinsic:
            var fittingSize = UIView.layoutFittingCompressedSize
            fittingSize.width = UIScreen.main.bounds.width
            let height = vc.view.systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow).height
            return min(height, UIScreen.main.bounds.height - 120)
        }
    }
    
}
