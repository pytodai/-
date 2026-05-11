//
//  SvobodenWidgetBundle.swift
//  SvobodenWidget
//
//  Created by Artem Sokolov on 5/11/26.
//

import WidgetKit
import SwiftUI

@main
struct SvobodenWidgetBundle: WidgetBundle {
    var body: some Widget {
        SvobodenWidget()
        SvobodenWidgetControl()
        SvobodenWidgetLiveActivity()
    }
}
