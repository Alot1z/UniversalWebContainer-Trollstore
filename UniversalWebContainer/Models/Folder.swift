import Foundation
import SwiftUI

// MARK: - Folder Model
struct Folder: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: FolderIcon
    var color: FolderColor
    var parentId: UUID?
    var webAppIds: [UUID]
    var sortOrder: SortOrder
    var isExpanded: Bool
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date
    var lastAccessedAt: Date?
    
    init(name: String, parentId: UUID? = nil, icon: FolderIcon = .folder, color: FolderColor = .blue) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.parentId = parentId
        self.webAppIds = []
        self.sortOrder = .name
        self.isExpanded = true
        self.isPinned = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Folder Icon
    enum FolderIcon: String, CaseIterable, Codable {
        case folder = "folder"
        case folderFill = "folder.fill"
        case briefcase = "briefcase"
        case briefcaseFill = "briefcase.fill"
        case house = "house"
        case houseFill = "house.fill"
        case star = "star"
        case starFill = "star.fill"
        case heart = "heart"
        case heartFill = "heart.fill"
        case gamecontroller = "gamecontroller"
        case gamecontrollerFill = "gamecontroller.fill"
        case book = "book"
        case bookFill = "book.fill"
        case cart = "cart"
        case cartFill = "cart.fill"
        case creditcard = "creditcard"
        case creditcardFill = "creditcard.fill"
        case envelope = "envelope"
        case envelopeFill = "envelope.fill"
        case phone = "phone"
        case phoneFill = "phone.fill"
        case camera = "camera"
        case cameraFill = "camera.fill"
        case music = "music.note"
        case musicFill = "music.note"
        case video = "video"
        case videoFill = "video.fill"
        case globe = "globe"
        case globeFill = "globe"
        case wifi = "wifi"
        case wifiFill = "wifi"
        case cloud = "cloud"
        case cloudFill = "cloud.fill"
        case lock = "lock"
        case lockFill = "lock.fill"
        case key = "key"
        case keyFill = "key.fill"
        case gear = "gear"
        case gearFill = "gear"
        case wrench = "wrench"
        case wrenchFill = "wrench.fill"
        case hammer = "hammer"
        case hammerFill = "hammer.fill"
        case paintbrush = "paintbrush"
        case paintbrushFill = "paintbrush.fill"
        case pencil = "pencil"
        case pencilFill = "pencil"
        case paperclip = "paperclip"
        case paperclipFill = "paperclip"
        case link = "link"
        case linkFill = "link"
        case person = "person"
        case personFill = "person.fill"
        case person2 = "person.2"
        case person2Fill = "person.2.fill"
        case person3 = "person.3"
        case person3Fill = "person.3.fill"
        case group = "person.3.sequence"
        case groupFill = "person.3.sequence.fill"
        case building = "building"
        case buildingFill = "building.fill"
        case building2 = "building.2"
        case building2Fill = "building.2.fill"
        case car = "car"
        case carFill = "car.fill"
        case bus = "bus"
        case busFill = "bus.fill"
        case tram = "tram"
        case tramFill = "tram.fill"
        case airplane = "airplane"
        case airplaneFill = "airplane"
        case ship = "ship"
        case shipFill = "ship"
        case bicycle = "bicycle"
        case bicycleFill = "bicycle"
        case scooter = "scooter"
        case scooterFill = "scooter"
        case motorcycle = "motorcycle"
        case motorcycleFill = "motorcycle"
        case train = "train.side.front.car"
        case trainFill = "train.side.front.car"
        case subway = "tram.fill"
        case subwayFill = "tram.fill"
        case taxi = "car.fill"
        case taxiFill = "car.fill"
        case ambulance = "cross.case"
        case ambulanceFill = "cross.case.fill"
        case firetruck = "flame"
        case firetruckFill = "flame.fill"
        case police = "shield"
        case policeFill = "shield.fill"
        case school = "graduationcap"
        case schoolFill = "graduationcap.fill"
        case university = "building.columns"
        case universityFill = "building.columns.fill"
        case hospital = "cross"
        case hospitalFill = "cross.fill"
        case pharmacy = "pills"
        case pharmacyFill = "pills.fill"
        case bank = "building.columns"
        case bankFill = "building.columns.fill"
        case postoffice = "envelope"
        case postofficeFill = "envelope.fill"
        case library = "books.vertical"
        case libraryFill = "books.vertical.fill"
        case museum = "building.columns"
        case museumFill = "building.columns.fill"
        case theater = "theatermasks"
        case theaterFill = "theatermasks.fill"
        case cinema = "film"
        case cinemaFill = "film.fill"
        case stadium = "sportscourt"
        case stadiumFill = "sportscourt.fill"
        case gym = "dumbbell"
        case gymFill = "dumbbell.fill"
        case pool = "drop"
        case poolFill = "drop.fill"
        case beach = "umbrella"
        case beachFill = "umbrella.fill"
        case mountain = "mountain.2"
        case mountainFill = "mountain.2.fill"
        case forest = "leaf"
        case forestFill = "leaf.fill"
        case park = "tree"
        case parkFill = "tree.fill"
        case garden = "flower"
        case gardenFill = "flower"
        case farm = "tractor"
        case farmFill = "tractor"
        case factory = "building.2"
        case factoryFill = "building.2.fill"
        case warehouse = "building"
        case warehouseFill = "building.fill"
        case office = "building.columns"
        case officeFill = "building.columns.fill"
        case shop = "cart"
        case shopFill = "cart.fill"
        case market = "cart.badge.plus"
        case marketFill = "cart.badge.plus"
        case restaurant = "fork.knife"
        case restaurantFill = "fork.knife"
        case cafe = "cup.and.saucer"
        case cafeFill = "cup.and.saucer.fill"
        case bar = "wineglass"
        case barFill = "wineglass.fill"
        case hotel = "bed.double"
        case hotelFill = "bed.double.fill"
        case hostel = "house"
        case hostelFill = "house.fill"
        case camping = "tent"
        case campingFill = "tent.fill"
        case rv = "car"
        case rvFill = "car.fill"
        case boat = "sailboat"
        case boatFill = "sailboat"
        case yacht = "sailboat.fill"
        case yachtFill = "sailboat.fill"
        case plane = "airplane"
        case planeFill = "airplane"
        case helicopter = "airplane"
        case helicopterFill = "airplane"
        case rocket = "airplane"
        case rocketFill = "airplane"
        case satellite = "antenna.radiowaves.left.and.right"
        case satelliteFill = "antenna.radiowaves.left.and.right"
        case telescope = "eye"
        case telescopeFill = "eye.fill"
        case microscope = "eye"
        case microscopeFill = "eye.fill"
        case testtube = "testtube.2"
        case testtubeFill = "testtube.2"
        case flask = "flask"
        case flaskFill = "flask.fill"
        case atom = "atom"
        case atomFill = "atom"
        case dna = "dna"
        case dnaFill = "dna"
        case brain = "brain"
        case brainFill = "brain"
        case heart = "heart"
        case heartFill = "heart.fill"
        case lung = "lungs"
        case lungFill = "lungs"
        case kidney = "drop"
        case kidneyFill = "drop.fill"
        case liver = "drop"
        case liverFill = "drop.fill"
        case stomach = "drop"
        case stomachFill = "drop.fill"
        case intestine = "drop"
        case intestineFill = "drop.fill"
        case bone = "drop"
        case boneFill = "drop.fill"
        case muscle = "drop"
        case muscleFill = "drop.fill"
        case skin = "drop"
        case skinFill = "drop.fill"
        case hair = "drop"
        case hairFill = "drop.fill"
        case nail = "drop"
        case nailFill = "drop.fill"
        case tooth = "drop"
        case toothFill = "drop.fill"
        case eye = "eye"
        case eyeFill = "eye.fill"
        case ear = "ear"
        case earFill = "ear"
        case nose = "nose"
        case noseFill = "nose"
        case mouth = "mouth"
        case mouthFill = "mouth"
        case tongue = "mouth"
        case tongueFill = "mouth"
        case throat = "mouth"
        case throatFill = "mouth"
        case vocal = "mouth"
        case vocalFill = "mouth"
        case vocal2 = "mouth"
        case vocal2Fill = "mouth"
        case vocal3 = "mouth"
        case vocal3Fill = "mouth"
        case vocal4 = "mouth"
        case vocal4Fill = "mouth"
        case vocal5 = "mouth"
        case vocal5Fill = "mouth"
        case vocal6 = "mouth"
        case vocal6Fill = "mouth"
        case vocal7 = "mouth"
        case vocal7Fill = "mouth"
        case vocal8 = "mouth"
        case vocal8Fill = "mouth"
        case vocal9 = "mouth"
        case vocal9Fill = "mouth"
        case vocal10 = "mouth"
        case vocal10Fill = "mouth"
        
        var displayName: String {
            switch self {
            case .folder: return "Folder"
            case .folderFill: return "Folder (Filled)"
            case .briefcase: return "Work"
            case .briefcaseFill: return "Work (Filled)"
            case .house: return "Home"
            case .houseFill: return "Home (Filled)"
            case .star: return "Favorites"
            case .starFill: return "Favorites (Filled)"
            case .heart: return "Personal"
            case .heartFill: return "Personal (Filled)"
            case .gamecontroller: return "Games"
            case .gamecontrollerFill: return "Games (Filled)"
            case .book: return "Education"
            case .bookFill: return "Education (Filled)"
            case .cart: return "Shopping"
            case .cartFill: return "Shopping (Filled)"
            case .creditcard: return "Finance"
            case .creditcardFill: return "Finance (Filled)"
            case .envelope: return "Communication"
            case .envelopeFill: return "Communication (Filled)"
            case .phone: return "Phone"
            case .phoneFill: return "Phone (Filled)"
            case .camera: return "Photos"
            case .cameraFill: return "Photos (Filled)"
            case .music: return "Music"
            case .musicFill: return "Music (Filled)"
            case .video: return "Video"
            case .videoFill: return "Video (Filled)"
            case .globe: return "Web"
            case .globeFill: return "Web (Filled)"
            case .wifi: return "Internet"
            case .wifiFill: return "Internet (Filled)"
            case .cloud: return "Cloud"
            case .cloudFill: return "Cloud (Filled)"
            case .lock: return "Security"
            case .lockFill: return "Security (Filled)"
            case .key: return "Access"
            case .keyFill: return "Access (Filled)"
            case .gear: return "Settings"
            case .gearFill: return "Settings (Filled)"
            case .wrench: return "Tools"
            case .wrenchFill: return "Tools (Filled)"
            case .hammer: return "Development"
            case .hammerFill: return "Development (Filled)"
            case .paintbrush: return "Design"
            case .paintbrushFill: return "Design (Filled)"
            case .pencil: return "Writing"
            case .pencilFill: return "Writing (Filled)"
            case .paperclip: return "Files"
            case .paperclipFill: return "Files (Filled)"
            case .link: return "Links"
            case .linkFill: return "Links (Filled)"
            case .person: return "Personal"
            case .personFill: return "Personal (Filled)"
            case .person2: return "Social"
            case .person2Fill: return "Social (Filled)"
            case .person3: return "Team"
            case .person3Fill: return "Team (Filled)"
            case .group: return "Group"
            case .groupFill: return "Group (Filled)"
            case .building: return "Business"
            case .buildingFill: return "Business (Filled)"
            case .building2: return "Corporate"
            case .building2Fill: return "Corporate (Filled)"
            case .car: return "Transport"
            case .carFill: return "Transport (Filled)"
            case .bus: return "Public Transport"
            case .busFill: return "Public Transport (Filled)"
            case .tram: return "Metro"
            case .tramFill: return "Metro (Filled)"
            case .airplane: return "Travel"
            case .airplaneFill: return "Travel (Filled)"
            case .ship: return "Maritime"
            case .shipFill: return "Maritime (Filled)"
            case .bicycle: return "Cycling"
            case .bicycleFill: return "Cycling (Filled)"
            case .scooter: return "Scooter"
            case .scooterFill: return "Scooter (Filled)"
            case .motorcycle: return "Motorcycle"
            case .motorcycleFill: return "Motorcycle (Filled)"
            case .train: return "Railway"
            case .trainFill: return "Railway (Filled)"
            case .subway: return "Subway"
            case .subwayFill: return "Subway (Filled)"
            case .taxi: return "Taxi"
            case .taxiFill: return "Taxi (Filled)"
            case .ambulance: return "Emergency"
            case .ambulanceFill: return "Emergency (Filled)"
            case .firetruck: return "Fire"
            case .firetruckFill: return "Fire (Filled)"
            case .police: return "Police"
            case .policeFill: return "Police (Filled)"
            case .school: return "School"
            case .schoolFill: return "School (Filled)"
            case .university: return "University"
            case .universityFill: return "University (Filled)"
            case .hospital: return "Hospital"
            case .hospitalFill: return "Hospital (Filled)"
            case .pharmacy: return "Pharmacy"
            case .pharmacyFill: return "Pharmacy (Filled)"
            case .bank: return "Bank"
            case .bankFill: return "Bank (Filled)"
            case .postoffice: return "Post Office"
            case .postofficeFill: return "Post Office (Filled)"
            case .library: return "Library"
            case .libraryFill: return "Library (Filled)"
            case .museum: return "Museum"
            case .museumFill: return "Museum (Filled)"
            case .theater: return "Theater"
            case .theaterFill: return "Theater (Filled)"
            case .cinema: return "Cinema"
            case .cinemaFill: return "Cinema (Filled)"
            case .stadium: return "Stadium"
            case .stadiumFill: return "Stadium (Filled)"
            case .gym: return "Gym"
            case .gymFill: return "Gym (Filled)"
            case .pool: return "Pool"
            case .poolFill: return "Pool (Filled)"
            case .beach: return "Beach"
            case .beachFill: return "Beach (Filled)"
            case .mountain: return "Mountain"
            case .mountainFill: return "Mountain (Filled)"
            case .forest: return "Forest"
            case .forestFill: return "Forest (Filled)"
            case .park: return "Park"
            case .parkFill: return "Park (Filled)"
            case .garden: return "Garden"
            case .gardenFill: return "Garden (Filled)"
            case .farm: return "Farm"
            case .farmFill: return "Farm (Filled)"
            case .factory: return "Factory"
            case .factoryFill: return "Factory (Filled)"
            case .warehouse: return "Warehouse"
            case .warehouseFill: return "Warehouse (Filled)"
            case .office: return "Office"
            case .officeFill: return "Office (Filled)"
            case .shop: return "Shop"
            case .shopFill: return "Shop (Filled)"
            case .market: return "Market"
            case .marketFill: return "Market (Filled)"
            case .restaurant: return "Restaurant"
            case .restaurantFill: return "Restaurant (Filled)"
            case .cafe: return "Cafe"
            case .cafeFill: return "Cafe (Filled)"
            case .bar: return "Bar"
            case .barFill: return "Bar (Filled)"
            case .hotel: return "Hotel"
            case .hotelFill: return "Hotel (Filled)"
            case .hostel: return "Hostel"
            case .hostelFill: return "Hostel (Filled)"
            case .camping: return "Camping"
            case .campingFill: return "Camping (Filled)"
            case .rv: return "RV"
            case .rvFill: return "RV (Filled)"
            case .boat: return "Boat"
            case .boatFill: return "Boat (Filled)"
            case .yacht: return "Yacht"
            case .yachtFill: return "Yacht (Filled)"
            case .plane: return "Plane"
            case .planeFill: return "Plane (Filled)"
            case .helicopter: return "Helicopter"
            case .helicopterFill: return "Helicopter (Filled)"
            case .rocket: return "Rocket"
            case .rocketFill: return "Rocket (Filled)"
            case .satellite: return "Satellite"
            case .satelliteFill: return "Satellite (Filled)"
            case .telescope: return "Telescope"
            case .telescopeFill: return "Telescope (Filled)"
            case .microscope: return "Microscope"
            case .microscopeFill: return "Microscope (Filled)"
            case .testtube: return "Test Tube"
            case .testtubeFill: return "Test Tube (Filled)"
            case .flask: return "Flask"
            case .flaskFill: return "Flask (Filled)"
            case .atom: return "Atom"
            case .atomFill: return "Atom (Filled)"
            case .dna: return "DNA"
            case .dnaFill: return "DNA (Filled)"
            case .brain: return "Brain"
            case .brainFill: return "Brain (Filled)"
            case .heart: return "Heart"
            case .heartFill: return "Heart (Filled)"
            case .lung: return "Lung"
            case .lungFill: return "Lung (Filled)"
            case .kidney: return "Kidney"
            case .kidneyFill: return "Kidney (Filled)"
            case .liver: return "Liver"
            case .liverFill: return "Liver (Filled)"
            case .stomach: return "Stomach"
            case .stomachFill: return "Stomach (Filled)"
            case .intestine: return "Intestine"
            case .intestineFill: return "Intestine (Filled)"
            case .bone: return "Bone"
            case .boneFill: return "Bone (Filled)"
            case .muscle: return "Muscle"
            case .muscleFill: return "Muscle (Filled)"
            case .skin: return "Skin"
            case .skinFill: return "Skin (Filled)"
            case .hair: return "Hair"
            case .hairFill: return "Hair (Filled)"
            case .nail: return "Nail"
            case .nailFill: return "Nail (Filled)"
            case .tooth: return "Tooth"
            case .toothFill: return "Tooth (Filled)"
            case .eye: return "Eye"
            case .eyeFill: return "Eye (Filled)"
            case .ear: return "Ear"
            case .earFill: return "Ear (Filled)"
            case .nose: return "Nose"
            case .noseFill: return "Nose (Filled)"
            case .mouth: return "Mouth"
            case .mouthFill: return "Mouth (Filled)"
            case .tongue: return "Tongue"
            case .tongueFill: return "Tongue (Filled)"
            case .throat: return "Throat"
            case .throatFill: return "Throat (Filled)"
            case .vocal: return "Vocal"
            case .vocalFill: return "Vocal (Filled)"
            case .vocal2: return "Vocal 2"
            case .vocal2Fill: return "Vocal 2 (Filled)"
            case .vocal3: return "Vocal 3"
            case .vocal3Fill: return "Vocal 3 (Filled)"
            case .vocal4: return "Vocal 4"
            case .vocal4Fill: return "Vocal 4 (Filled)"
            case .vocal5: return "Vocal 5"
            case .vocal5Fill: return "Vocal 5 (Filled)"
            case .vocal6: return "Vocal 6"
            case .vocal6Fill: return "Vocal 6 (Filled)"
            case .vocal7: return "Vocal 7"
            case .vocal7Fill: return "Vocal 7 (Filled)"
            case .vocal8: return "Vocal 8"
            case .vocal8Fill: return "Vocal 8 (Filled)"
            case .vocal9: return "Vocal 9"
            case .vocal9Fill: return "Vocal 9 (Filled)"
            case .vocal10: return "Vocal 10"
            case .vocal10Fill: return "Vocal 10 (Filled)"
            }
        }
    }
    
    // MARK: - Folder Color
    enum FolderColor: String, CaseIterable, Codable {
        case red = "red"
        case orange = "orange"
        case yellow = "yellow"
        case green = "green"
        case blue = "blue"
        case purple = "purple"
        case pink = "pink"
        case brown = "brown"
        case gray = "gray"
        case black = "black"
        case white = "white"
        case cyan = "cyan"
        case indigo = "indigo"
        case teal = "teal"
        case mint = "mint"
        case lavender = "lavender"
        case coral = "coral"
        case salmon = "salmon"
        case gold = "gold"
        case silver = "silver"
        case bronze = "bronze"
        case copper = "copper"
        case platinum = "platinum"
        case titanium = "titanium"
        case steel = "steel"
        case iron = "iron"
        case aluminum = "aluminum"
        case zinc = "zinc"
        case nickel = "nickel"
        case chrome = "chrome"
        case brass = "brass"
        case pewter = "pewter"
        case gunmetal = "gunmetal"
        case rosegold = "rosegold"
        case whitegold = "whitegold"
        case yellowgold = "yellowgold"
        case redgold = "redgold"
        case greengold = "greengold"
        case bluegold = "bluegold"
        case purplegold = "purplegold"
        case pinkgold = "pinkgold"
        case orangegold = "orangegold"
        case yellowgold2 = "yellowgold2"
        case redgold2 = "redgold2"
        case greengold2 = "greengold2"
        case bluegold2 = "bluegold2"
        case purplegold2 = "purplegold2"
        case pinkgold2 = "pinkgold2"
        case orangegold2 = "orangegold2"
        case yellowgold3 = "yellowgold3"
        case redgold3 = "redgold3"
        case greengold3 = "greengold3"
        case bluegold3 = "bluegold3"
        case purplegold3 = "purplegold3"
        case pinkgold3 = "pinkgold3"
        case orangegold3 = "orangegold3"
        case yellowgold4 = "yellowgold4"
        case redgold4 = "redgold4"
        case greengold4 = "greengold4"
        case bluegold4 = "bluegold4"
        case purplegold4 = "purplegold4"
        case pinkgold4 = "pinkgold4"
        case orangegold4 = "orangegold4"
        case yellowgold5 = "yellowgold5"
        case redgold5 = "redgold5"
        case greengold5 = "greengold5"
        case bluegold5 = "bluegold5"
        case purplegold5 = "purplegold5"
        case pinkgold5 = "pinkgold5"
        case orangegold5 = "orangegold5"
        
        var color: Color {
            switch self {
            case .red: return .red
            case .orange: return .orange
            case .yellow: return .yellow
            case .green: return .green
            case .blue: return .blue
            case .purple: return .purple
            case .pink: return .pink
            case .brown: return .brown
            case .gray: return .gray
            case .black: return .black
            case .white: return .white
            case .cyan: return .cyan
            case .indigo: return .indigo
            case .teal: return .teal
            case .mint: return .mint
            case .lavender: return .purple.opacity(0.7)
            case .coral: return .orange.opacity(0.8)
            case .salmon: return .pink.opacity(0.7)
            case .gold: return .yellow
            case .silver: return .gray
            case .bronze: return .brown
            case .copper: return .orange
            case .platinum: return .gray.opacity(0.8)
            case .titanium: return .gray.opacity(0.6)
            case .steel: return .gray.opacity(0.5)
            case .iron: return .gray.opacity(0.4)
            case .aluminum: return .gray.opacity(0.3)
            case .zinc: return .gray.opacity(0.2)
            case .nickel: return .gray.opacity(0.1)
            case .chrome: return .gray.opacity(0.9)
            case .brass: return .yellow.opacity(0.8)
            case .pewter: return .gray.opacity(0.7)
            case .gunmetal: return .gray.opacity(0.6)
            case .rosegold: return .pink.opacity(0.8)
            case .whitegold: return .yellow.opacity(0.9)
            case .yellowgold: return .yellow
            case .redgold: return .red.opacity(0.8)
            case .greengold: return .green.opacity(0.8)
            case .bluegold: return .blue.opacity(0.8)
            case .purplegold: return .purple.opacity(0.8)
            case .pinkgold: return .pink.opacity(0.8)
            case .orangegold: return .orange.opacity(0.8)
            case .yellowgold2: return .yellow.opacity(0.9)
            case .redgold2: return .red.opacity(0.9)
            case .greengold2: return .green.opacity(0.9)
            case .bluegold2: return .blue.opacity(0.9)
            case .purplegold2: return .purple.opacity(0.9)
            case .pinkgold2: return .pink.opacity(0.9)
            case .orangegold2: return .orange.opacity(0.9)
            case .yellowgold3: return .yellow.opacity(0.8)
            case .redgold3: return .red.opacity(0.8)
            case .greengold3: return .green.opacity(0.8)
            case .bluegold3: return .blue.opacity(0.8)
            case .purplegold3: return .purple.opacity(0.8)
            case .pinkgold3: return .pink.opacity(0.8)
            case .orangegold3: return .orange.opacity(0.8)
            case .yellowgold4: return .yellow.opacity(0.7)
            case .redgold4: return .red.opacity(0.7)
            case .greengold4: return .green.opacity(0.7)
            case .bluegold4: return .blue.opacity(0.7)
            case .purplegold4: return .purple.opacity(0.7)
            case .pinkgold4: return .pink.opacity(0.7)
            case .orangegold4: return .orange.opacity(0.7)
            case .yellowgold5: return .yellow.opacity(0.6)
            case .redgold5: return .red.opacity(0.6)
            case .greengold5: return .green.opacity(0.6)
            case .bluegold5: return .blue.opacity(0.6)
            case .purplegold5: return .purple.opacity(0.6)
            case .pinkgold5: return .pink.opacity(0.6)
            case .orangegold5: return .orange.opacity(0.6)
            }
        }
        
        var displayName: String {
            switch self {
            case .red: return "Red"
            case .orange: return "Orange"
            case .yellow: return "Yellow"
            case .green: return "Green"
            case .blue: return "Blue"
            case .purple: return "Purple"
            case .pink: return "Pink"
            case .brown: return "Brown"
            case .gray: return "Gray"
            case .black: return "Black"
            case .white: return "White"
            case .cyan: return "Cyan"
            case .indigo: return "Indigo"
            case .teal: return "Teal"
            case .mint: return "Mint"
            case .lavender: return "Lavender"
            case .coral: return "Coral"
            case .salmon: return "Salmon"
            case .gold: return "Gold"
            case .silver: return "Silver"
            case .bronze: return "Bronze"
            case .copper: return "Copper"
            case .platinum: return "Platinum"
            case .titanium: return "Titanium"
            case .steel: return "Steel"
            case .iron: return "Iron"
            case .aluminum: return "Aluminum"
            case .zinc: return "Zinc"
            case .nickel: return "Nickel"
            case .chrome: return "Chrome"
            case .brass: return "Brass"
            case .pewter: return "Pewter"
            case .gunmetal: return "Gunmetal"
            case .rosegold: return "Rose Gold"
            case .whitegold: return "White Gold"
            case .yellowgold: return "Yellow Gold"
            case .redgold: return "Red Gold"
            case .greengold: return "Green Gold"
            case .bluegold: return "Blue Gold"
            case .purplegold: return "Purple Gold"
            case .pinkgold: return "Pink Gold"
            case .orangegold: return "Orange Gold"
            case .yellowgold2: return "Yellow Gold 2"
            case .redgold2: return "Red Gold 2"
            case .greengold2: return "Green Gold 2"
            case .bluegold2: return "Blue Gold 2"
            case .purplegold2: return "Purple Gold 2"
            case .pinkgold2: return "Pink Gold 2"
            case .orangegold2: return "Orange Gold 2"
            case .yellowgold3: return "Yellow Gold 3"
            case .redgold3: return "Red Gold 3"
            case .greengold3: return "Green Gold 3"
            case .bluegold3: return "Blue Gold 3"
            case .purplegold3: return "Purple Gold 3"
            case .pinkgold3: return "Pink Gold 3"
            case .orangegold3: return "Orange Gold 3"
            case .yellowgold4: return "Yellow Gold 4"
            case .redgold4: return "Red Gold 4"
            case .greengold4: return "Green Gold 4"
            case .bluegold4: return "Blue Gold 4"
            case .purplegold4: return "Purple Gold 4"
            case .pinkgold4: return "Pink Gold 4"
            case .orangegold4: return "Orange Gold 4"
            case .yellowgold5: return "Yellow Gold 5"
            case .redgold5: return "Red Gold 5"
            case .greengold5: return "Green Gold 5"
            case .bluegold5: return "Blue Gold 5"
            case .purplegold5: return "Purple Gold 5"
            case .pinkgold5: return "Pink Gold 5"
            case .orangegold5: return "Orange Gold 5"
            }
        }
    }
    
    // MARK: - Sort Order
    enum SortOrder: String, CaseIterable, Codable {
        case name = "name"
        case lastAccessed = "last_accessed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case webAppCount = "webapp_count"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .name: return "Name"
            case .lastAccessed: return "Last Accessed"
            case .createdAt: return "Created"
            case .updatedAt: return "Updated"
            case .webAppCount: return "WebApp Count"
            case .custom: return "Custom"
            }
        }
    }
    
    // MARK: - Computed Properties
    var webAppCount: Int {
        return webAppIds.count
    }
    
    var hasWebApps: Bool {
        return !webAppIds.isEmpty
    }
    
    var isEmpty: Bool {
        return webAppIds.isEmpty
    }
    
    var isRoot: Bool {
        return parentId == nil
    }
    
    var hasChildren: Bool {
        return false // Will be computed by FolderManager
    }
    
    // MARK: - Methods
    mutating func addWebApp(_ webAppId: UUID) {
        if !webAppIds.contains(webAppId) {
            webAppIds.append(webAppId)
            updatedAt = Date()
        }
    }
    
    mutating func removeWebApp(_ webAppId: UUID) {
        webAppIds.removeAll { $0 == webAppId }
        updatedAt = Date()
    }
    
    mutating func updateLastAccessed() {
        lastAccessedAt = Date()
        updatedAt = Date()
    }
    
    mutating func togglePin() {
        isPinned.toggle()
        updatedAt = Date()
    }
    
    mutating func toggleExpanded() {
        isExpanded.toggle()
        updatedAt = Date()
    }
    
    mutating func updateSortOrder(_ newSortOrder: SortOrder) {
        sortOrder = newSortOrder
        updatedAt = Date()
    }
    
    mutating func updateIcon(_ newIcon: FolderIcon) {
        icon = newIcon
        updatedAt = Date()
    }
    
    mutating func updateColor(_ newColor: FolderColor) {
        color = newColor
        updatedAt = Date()
    }
    
    // MARK: - Validation
    var isValid: Bool {
        return !name.isEmpty
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if name.isEmpty {
            errors.append("Folder name cannot be empty")
        }
        
        if name.count > 50 {
            errors.append("Folder name cannot exceed 50 characters")
        }
        
        return errors
    }
}

// MARK: - Folder Extensions
extension Folder {
    static let sampleFolders: [Folder] = [
        Folder(name: "Work", icon: .briefcase, color: .blue),
        Folder(name: "Personal", icon: .heart, color: .pink),
        Folder(name: "Social", icon: .person2, color: .green),
        Folder(name: "Shopping", icon: .cart, color: .orange),
        Folder(name: "Entertainment", icon: .star, color: .purple),
        Folder(name: "Education", icon: .book, color: .indigo),
        Folder(name: "Finance", icon: .creditcard, color: .green),
        Folder(name: "Travel", icon: .airplane, color: .cyan),
        Folder(name: "Health", icon: .heart, color: .red),
        Folder(name: "Sports", icon: .sportscourt, color: .orange),
        Folder(name: "Music", icon: .music, color: .pink),
        Folder(name: "Video", icon: .video, color: .purple),
        Folder(name: "Games", icon: .gamecontroller, color: .yellow),
        Folder(name: "News", icon: .newspaper, color: .blue),
        Folder(name: "Weather", icon: .cloud, color: .cyan),
        Folder(name: "Maps", icon: .map, color: .green),
        Folder(name: "Tools", icon: .wrench, color: .gray),
        Folder(name: "Settings", icon: .gear, color: .gray),
        Folder(name: "Favorites", icon: .star, color: .yellow),
        Folder(name: "Recent", icon: .clock, color: .blue)
    ]
    
    static func createSampleFolder(name: String, icon: FolderIcon = .folder, color: FolderColor = .blue) -> Folder {
        return Folder(name: name, icon: icon, color: color)
    }
}

// MARK: - Folder Sorting
extension Folder {
    static func sorted(_ folders: [Folder], by sortOrder: SortOrder, ascending: Bool = true) -> [Folder] {
        return folders.sorted { first, second in
            let result: Bool
            switch sortOrder {
            case .name:
                result = first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            case .lastAccessed:
                let firstDate = first.lastAccessedAt ?? first.createdAt
                let secondDate = second.lastAccessedAt ?? second.createdAt
                result = firstDate < secondDate
            case .createdAt:
                result = first.createdAt < second.createdAt
            case .updatedAt:
                result = first.updatedAt < second.updatedAt
            case .webAppCount:
                result = first.webAppCount < second.webAppCount
            case .custom:
                result = first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            }
            return ascending ? result : !result
        }
    }
}

// MARK: - Folder Utilities
extension Folder {
    static let defaultFolder = Folder(name: "Default", icon: .folder, color: .blue)
    static let uncategorizedFolder = Folder(name: "Uncategorized", icon: .folder, color: .gray)
    static let trashFolder = Folder(name: "Trash", icon: .trash, color: .red)
    
    static func createDefaultFolders() -> [Folder] {
        return [
            Folder(name: "Work", icon: .briefcase, color: .blue),
            Folder(name: "Personal", icon: .heart, color: .pink),
            Folder(name: "Social", icon: .person2, color: .green),
            Folder(name: "Shopping", icon: .cart, color: .orange),
            Folder(name: "Entertainment", icon: .star, color: .purple)
        ]
    }
}
