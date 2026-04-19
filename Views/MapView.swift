//
//  MapView.swift
//  GameRoulette
//
//  Created by Erik Camacho on 4/18/26.
//
import SwiftUI
import MapKit

struct MapView: View {
    let coordinate: CLLocationCoordinate2D
    let locationName: String
    let theme: any Theme
    @State private var region: MKCoordinateRegion
    
    init(coordinate: CLLocationCoordinate2D, locationName: String, theme: any Theme) {
        self.coordinate = coordinate
        self.locationName = locationName
        self.theme = theme
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        Map(coordinateRegion: $region,
            interactionModes: .all,
            showsUserLocation: false,
            annotationItems: [MapAnnotationItem(coordinate: coordinate, name: locationName)]
        ) { item in
            MapMarker(coordinate: item.coordinate, tint: Color(theme.accentColor))
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        let placemark = MKPlacemark(coordinate: coordinate)
                        let mapItem = MKMapItem(placemark: placemark)
                        mapItem.name = locationName
                        mapItem.openInMaps()
                    }) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .padding(8)
                            .background(theme.cardBackgroundColor)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            }
        )
    }
}

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
}
