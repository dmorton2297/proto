//
//  PictureEntryTableViewCell.swift
//  proto
//
//  Created by Dan Morton on 2/25/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit

class PictureEntryTableViewCell: UITableViewCell
{
    @IBOutlet weak var locationTextLabel: UILabel!
    @IBOutlet weak var coordinatesTextLabel: UILabel!
    @IBOutlet weak var selfieImageView: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeCountLabel: UILabel!
    
    
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        selfieImageView.contentMode = UIViewContentMode.ScaleAspectFill
        // Initialization code
    }
    

}
