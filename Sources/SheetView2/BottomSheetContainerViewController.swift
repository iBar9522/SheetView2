//
//  BottomSheetContainerViewController.swift
//  Delivery
//
//  Created by Aibar Abylgazin on 16.08.2021.
//

import UIKit

public class BottomSheetContainerViewController<Content: UIViewController, BottomSheet: UIViewController>: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Children
    let contentViewController: Content
    let bottomSheetViewController: BottomSheet
    
    private let configuration: BottomSheetConfiguration
    
    // MARK: - Properties
    var state: BottomSheetState = .initial
    
    lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer()
        panGesture.delegate = self
        panGesture.addTarget(self, action: #selector(handlePan(_:)))
        return panGesture
    }()
    
    private var topConstraint = NSLayoutConstraint()
    
    // MARK: - Configuration
    public struct BottomSheetConfiguration {
        let height: CGFloat
        let initialOffset: CGFloat
        
        var isVisisble: Bool
        
        public init(
            height: CGFloat,
            initialOffset: CGFloat,
            isVisisble: Bool = false
        ) {
            self.height = height
            self.initialOffset = initialOffset
            self.isVisisble = isVisisble
        }
    }
    
    enum BottomSheetState {
        case initial
        case full
    }
    
    // MARK: - Lifecycle
    public init(contentViewController: Content, bottomSheetViewController: BottomSheet, configuration: BottomSheetConfiguration) {
        self.contentViewController = contentViewController
        self.bottomSheetViewController = bottomSheetViewController
        self.configuration = configuration
        
        super.init(nibName: nil, bundle: nil)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: bottomSheetViewController.view)
        let velocity = sender.velocity(in: bottomSheetViewController.view)
        let yTranslationMagnitude = translation.y.magnitude
        
        switch sender.state {
        case .began, .changed:
            if self.state == .full {
                guard translation.y > 0 else { return }
                topConstraint.constant = -(configuration.height - yTranslationMagnitude)
                view.layoutIfNeeded()
            } else {
                let newConstant = -(configuration.height + yTranslationMagnitude)
                guard translation.y < 0 else { return }
                guard newConstant.magnitude < configuration.height else {
                    showBottomSheet()
                    return
                }
                topConstraint.constant = newConstant
                view.layoutIfNeeded()
            }
        case .ended:
            if self.state == .full {
                if yTranslationMagnitude >= configuration.height / 2 || velocity.y > 1000 {
                    hideBottomSheet()
                } else {
                    showBottomSheet()
                }
            } else {
                if yTranslationMagnitude >= configuration.height / 2 || velocity.y < -1000 {
                    showBottomSheet()
                } else {
                    hideBottomSheet()
                }
            }
        case .failed:
            if self.state == .full {
                showBottomSheet()
            } else {
                hideBottomSheet()
            }
        default: break
        }
    }
    
    // MARK: - UIGestureRecognizer Delegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension BottomSheetContainerViewController {
    // MARK: - Bottom Sheet Actions
    func showBottomSheet(animated: Bool = true) {
        self.topConstraint.constant = -configuration.height
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.state = .full
            })
        } else {
            self.view.layoutIfNeeded()
            self.state = .full
        }
    }
    
    func hideBottomSheet(animated: Bool = true) {
        self.topConstraint.constant = -configuration.initialOffset
        
        if animated {
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.5,
                           options: [.curveEaseOut],
                           animations: {
                            self.view.layoutIfNeeded()
                           }, completion: { _ in
                            self.state = .initial
                           })
        } else {
            self.view.layoutIfNeeded()
            self.state = .initial
        }
    }
}

extension BottomSheetContainerViewController {
    private func setupUI() {
        // 1
        self.addChild(contentViewController)
        self.addChild(bottomSheetViewController)
        
        // 2
        self.view.addSubview(contentViewController.view)
        self.view.addSubview(bottomSheetViewController.view)
        
        // 3
        bottomSheetViewController.view.addGestureRecognizer(panGesture)
        
        // 4
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // 5
        NSLayoutConstraint.activate([
            contentViewController.view.leftAnchor
                .constraint(equalTo: self.view.leftAnchor),
            contentViewController.view.rightAnchor
                .constraint(equalTo: self.view.rightAnchor),
            contentViewController.view.topAnchor
                .constraint(equalTo: self.view.topAnchor),
            contentViewController.view.bottomAnchor
                .constraint(equalTo: self.view.bottomAnchor)
        ])
        
        // 6
        contentViewController.didMove(toParent: self)
        
        // 7
        topConstraint = bottomSheetViewController.view.topAnchor
            .constraint(equalTo: self.view.bottomAnchor,
                        constant: -configuration.initialOffset)
        
        // 8
        NSLayoutConstraint.activate([
            bottomSheetViewController.view.heightAnchor
                .constraint(equalToConstant: configuration.height),
            bottomSheetViewController.view.leftAnchor
                .constraint(equalTo: self.view.leftAnchor),
            bottomSheetViewController.view.rightAnchor
                .constraint(equalTo: self.view.rightAnchor),
            topConstraint
        ])
        
        // 9
        bottomSheetViewController.didMove(toParent: self)
    }
}

