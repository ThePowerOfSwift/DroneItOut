//
//  DJICollectionController.swift
//  DroneItOut
//
//  Created by Daniel Nguyen on 9/29/17.
//  Copyright © 2017 DJI. All rights reserved.
//

import Foundation
public class DJIMissionManagerDelegate {
    
}
public class DJICustomMission
{
    var Id:Int!
    init(id: Int){
        self.Id = id
    }
    var description: String {
        return "{ID=\(Id)}"
    }
}
