//
//  CLLocationEx.swift
//  SafeDriveExample
//
//  Created by younggi.lee on 29/11/2017.
//  Copyright © 2017 YKLEE. All rights reserved.
//

import UIKit
import CoreLocation

public struct CLLocationBessel2D {
    
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    
    public init() {
        self.latitude = 0
        self.longitude = 0
    }
    
    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = latitude;
        self.longitude = longitude;
    }
}

extension CLLocation {
    
    convenience init(bessel: CLLocationBessel2D) {
        self.init(coordinate: CLLocation.besselToWgs84(bessel: bessel))
    }
    
    convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    func bessel() -> CLLocationBessel2D {
        return CLLocation.wgs84ToBessel(coordinate: coordinate)
    }
    
    func location(distance: CLLocationDistance, angle: CGFloat) -> CLLocation {
        let angularDistance = distance / 6371000.0
        
        let angleR = angle.toRadian()
        let latR = self.coordinate.latitude.toRadian()
        let lonR = self.coordinate.longitude.toRadian()
        
        let lat2 = asin( sin(latR) * cos(angularDistance) + cos(latR) * sin(angularDistance) * cos(angleR) );
        let lon2 = lonR + atan2( sin(angleR) * sin(angularDistance) * cos(latR), cos(angularDistance) - sin(latR) * sin(lat2) );
        
        let newCoordinate = CLLocationCoordinate2D(latitude: lat2.toDegree(), longitude: lon2.toDegree())
        return CLLocation.init(coordinate: newCoordinate, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: timestamp)
    }
    
    static func wgs84ToBessel(coordinate: CLLocationCoordinate2D) -> CLLocationBessel2D {
        
        let wgs84_a = 6378137.0
        let wgs84_b = 6378137.0 - 6378137.0 / 298.257223563
        let wgs84_ee = 2.0 * (1.0 / 298.257223563) - (1.0 / 298.257223563) * (1.0 / 298.257223563)
        
        let delta_x = 128.0
        let delta_y = -481.0
        let delta_z = -664.0
        let delta_aa = -739.845
        let delta_af = -0.000010037483
        
        let wgs84_lat_r = coordinate.latitude * Double.pi / 180.0
        let wgs84_long_r = coordinate.longitude * Double.pi / 180.0
        let wgs84_height = 0.0
        
        let wgs84_rn = wgs84_a / sqrt(1.0 - wgs84_ee * pow(sin(wgs84_lat_r), 2.0));
        let wgs84_rm = wgs84_a * (1.0 - wgs84_ee) / pow(sqrt(1.0 - wgs84_ee * pow(sin(wgs84_lat_r), 2.0)), 3.0);
        
        let delta_a = -delta_x * sin(wgs84_lat_r) * cos(wgs84_long_r) - delta_y * sin(wgs84_lat_r) * sin(wgs84_long_r)
        let delta_b = delta_z * cos(wgs84_lat_r) + delta_aa * (wgs84_rn * wgs84_ee * sin(wgs84_lat_r) * cos(wgs84_lat_r)) / wgs84_a
        let delta_m = (wgs84_rm + wgs84_height) * sin(Double.pi / 180.0 * 1.0 / 3600.0)
        let delta_pi = (delta_a + delta_b + delta_af * (wgs84_rm * wgs84_a / wgs84_b + wgs84_rn * wgs84_b / wgs84_a) * sin(wgs84_lat_r) * cos(wgs84_lat_r)) / delta_m
        let delta_lamda = (-delta_x * sin(wgs84_long_r) + delta_y * cos(wgs84_long_r)) /
                            ((wgs84_rn + wgs84_height) * cos(wgs84_lat_r) * sin(Double.pi / 180.0 * 1.0 / 3600.0));
        
        let bessel_lat = coordinate.latitude + delta_pi / 3600.0
        let bessel_long = coordinate.longitude + delta_lamda / 3600.0
        
        return CLLocationBessel2D(latitude: bessel_lat, longitude: bessel_long)
    }
    
    static func besselToWgs84(bessel: CLLocationBessel2D) -> CLLocationCoordinate2D {
        
        let bessel_a = 6377397.155
        let bessel_b = 6377397.155 - 6377397.155 / 299.1528128
        let bessel_latitude_r = bessel.latitude * Double.pi / 180.0
        let bessel_longitude_r = bessel.longitude * Double.pi / 180.0
        
        let bessel_f = (bessel_a - bessel_b) / bessel_a
        let sqre = 2 * bessel_f - bessel_f * bessel_f
        let bessel_n = bessel_a / sqrt(1 - sqre * sin(bessel_latitude_r) * sin(bessel_latitude_r))
        let height = 0.0
        
        let coordinate_x = (bessel_n + height) * cos(bessel_latitude_r) * cos(bessel_longitude_r) + -147.0
        let coordinate_y = (bessel_n + height) * cos(bessel_latitude_r) * sin(bessel_longitude_r) + 506.0
        let coordinate_z = (bessel_n * (1 - sqre) + height) * sin(bessel_latitude_r) + 687.0
        
        let wgs84_a = 6378137.0
        let wgs84_b = 6378137.0 - 6378137.0 / 298.257223563
        let wgs84_p = sqrt(coordinate_x * coordinate_x + coordinate_y * coordinate_y)
        let wgs84_theta = atan((coordinate_z * wgs84_a) / (wgs84_p * wgs84_b))
        let wgs84_sqrep = (wgs84_a * wgs84_a - wgs84_b * wgs84_b) / (wgs84_b * wgs84_b)
        let wgs84_f = (wgs84_a - wgs84_b) / wgs84_a
        let wgs84_sqre = 2 * wgs84_f - wgs84_f * wgs84_f
        
        let wgs84_latitude_r = atan((coordinate_z + wgs84_sqrep * wgs84_b * sin(wgs84_theta) * sin(wgs84_theta) * sin(wgs84_theta)) /
                                    (wgs84_p - wgs84_sqre * wgs84_a * cos(wgs84_theta) * cos(wgs84_theta) * cos(wgs84_theta)));
        let wgs84_longitude_r = atan2(coordinate_y, coordinate_x);
        let wgs84_latitude = wgs84_latitude_r * 180.0 / Double.pi;
        let wgs84_longitude = wgs84_longitude_r * 180.0 / Double.pi;
        
        return CLLocationCoordinate2D(latitude: wgs84_latitude, longitude: wgs84_longitude)
    }
}
