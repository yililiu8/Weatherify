//
//  AllPlaylistsTableViewCell.swift
//  Weatherify
//
//  Created by Yili Liu on 3/23/21.
//

import UIKit

class AllPlaylistsTableViewCell: UITableViewCell {

    @IBOutlet weak var cover: UIImageView!
    @IBOutlet weak var owner: UILabel!
    @IBOutlet weak var name: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.frame.size.height = 76
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
