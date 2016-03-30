//
//  Model.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 14/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

private let sharedInstance = Model()

class Model: NSObject {
	var fileName: String?
	var openedSVDFile: SVDFile?

	var selectedRegistrations: [SVDRegistration] = []
	var selectedLiveSets: [SVDLiveSet] = []
	var selectedTones: [SVDTone] = []

	var filteredRegistrations: [SVDRegistration] = []
	var filteredLiveSets: [SVDLiveSet] = []
	var filteredTones: [SVDTone] = []

	class var singleton: Model {
		return sharedInstance
	}
}
