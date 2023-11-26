//
//  Model.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 14/12/14.
//

import Cocoa

class Model: NSObject {
	var fileName: String?
	var openedSVDFile: SVDFile?

	var selectedRegistrations: [SVDRegistration] = []
	var selectedLiveSets: [SVDLiveSet] = []
	var selectedTones: [SVDTone] = []

	var filteredRegistrations: [SVDRegistration] = []
	var filteredLiveSets: [SVDLiveSet] = []
	var filteredTones: [SVDTone] = []
}
