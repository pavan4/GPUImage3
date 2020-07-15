Pod::Spec.new do |s|
    s.name     = 'PixelSDK-GPUImage3'
    s.module_name = 'GPUImage'
    s.version  = '1.1.3'
    s.license  = 'BSD'
    s.summary  = 'An open source iOS framework for GPU-based image and video processing.'
    s.homepage = 'https://github.com/GottaYotta/GPUImage3'
    s.author   = { 'Brad Larson' => 'contact@sunsetlakesoftware.com' }
    s.source   = { :git => 'https://github.com/GottaYotta/GPUImage3.git', :tag => s.version }

    s.source_files = 'framework/Source/**/*.{swift,h,metal}'
    s.public_header_files = 'framework/Source/Empty.h'

    s.ios.deployment_target = '9.0'
    s.frameworks   = ['Metal', 'QuartzCore', 'AVFoundation']
    s.swift_version = '5.0'
end