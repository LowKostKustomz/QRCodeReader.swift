/*
 * QRCodeReader.swift
 *
 * Copyright 2014-present Yannick Loriot.
 * http://yannickloriot.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import UIKit

public enum QRCodeReaderViewAppearance {
    public static var torchButtonImage: UIImage?
    public static var switchButtonImage: UIImage?
    public static var cancelButtonImage: UIImage?
    
    public static var hintText: String?
}

final class QRCodeReaderView: UIView, QRCodeReaderDisplayable {
    lazy var overlayView: UIView? = {
        let ov = ReaderOverlayView()
        
        ov.backgroundColor                           = .clear
        ov.clipsToBounds                             = true
        ov.translatesAutoresizingMaskIntoConstraints = false
        
        return ov
    }()
    
    let cameraView: UIView = {
        let cv = UIView()
        
        cv.clipsToBounds                             = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        
        return cv
    }()
    
    lazy var cancelButton: UIButton? = {
        return self.getButton(with: QRCodeReaderViewAppearance.cancelButtonImage)
    }()
    
    lazy var switchCameraButton: UIButton? = {
        return self.getButton(with: QRCodeReaderViewAppearance.switchButtonImage)
    }()
    
    lazy var toggleTorchButton: UIButton? = {
        return self.getButton(with: QRCodeReaderViewAppearance.torchButtonImage)
    }()
    
    func getButton(with image: UIImage?) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.tintColor = UIColor.white
        button.layer.cornerRadius = 10
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 9.0, *) {
            button.widthAnchor.constraint(equalToConstant: 60).isActive = true
            button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        }
        
        return button
    }
    
    func getLabel(with text: String?) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.font = label.font.withSize(16)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 1.4
        
        label.attributedText = NSAttributedString(string: (text ?? ""), attributes: [NSParagraphStyleAttributeName: paragraph])
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }
    
    func setupComponents(showCancelButton: Bool, showSwitchCameraButton: Bool, showTorchButton: Bool, showOverlayView: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        
        addComponents()
        
        cancelButton?.isHidden       = !showCancelButton
        switchCameraButton?.isHidden = !showSwitchCameraButton
        toggleTorchButton?.isHidden  = !showTorchButton
        overlayView?.isHidden        = !showOverlayView
        
        guard let cb = cancelButton, let scb = switchCameraButton, let ttb = toggleTorchButton, let ov = overlayView else { return }
        
        let labelView = UIView()
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        labelView.layer.cornerRadius = 10
        labelView.clipsToBounds = true
        
        let hintLabel: UILabel = getLabel(with: QRCodeReaderViewAppearance.hintText)
        
        let views = ["cv": cameraView, "ov": ov, "cb": cb, "scb": scb, "ttb": ttb, "hl": hintLabel, "lv": labelView]
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[cv]|", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[cv]|", options: [], metrics: nil, views: views))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[ov]|", options: [], metrics: nil, views: views))
        
        if QRCodeReaderViewAppearance.hintText != nil {
            labelView.addSubview(hintLabel)
            addSubview(labelView)
            
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[hl]-16-|", options: [], metrics: nil, views: views))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[hl]-8-|", options: [], metrics: nil, views: views))
            
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-24-[lv]-24-|", options: [], metrics: nil, views: views))
            
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-32-[lv][ov]-108-|", options: [], metrics: nil, views: views))
        } else {
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-32-[ov]-108-|", options: [], metrics: nil, views: views))
        }
    }
    
    // MARK: - Scan Result Indication
    
    func startTimerForBorderReset() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            if let ovl = self.overlayView as? ReaderOverlayView {
                ovl.overlayColor = .white
            }
        }
    }
    
    func addRedBorder() {
        self.startTimerForBorderReset()
        if let ovl = self.overlayView as? ReaderOverlayView {
            ovl.overlayColor = .red
        }
    }
    
    func addGreenBorder() {
        self.startTimerForBorderReset()
        if let ovl = self.overlayView as? ReaderOverlayView {
            ovl.overlayColor = .green
        }
    }
    
    // MARK: - Convenience Methods
    
    private func addComponents() {
        if #available(iOS 9.0, *) {
            addSubview(cameraView)
            let stackView = UIStackView()
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.distribution = .equalSpacing
            
            addSubview(stackView)
            
            let sideMargin: CGFloat = 64
            
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24).isActive = true
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: sideMargin).isActive = true
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -sideMargin).isActive = true
            stackView.heightAnchor.constraint(equalToConstant: 60).isActive = true
            
            if let cb = cancelButton {
                stackView.addArrangedSubview(cb)
            }
            
            if let ttb = toggleTorchButton {
                stackView.addArrangedSubview(ttb)
            }
            
            if let scb = switchCameraButton {
                stackView.addArrangedSubview(scb)
            }
        }
        
        if let ov = overlayView {
            addSubview(ov)
        }
    }
}
