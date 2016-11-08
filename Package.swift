import PackageDescription

let package = Package(
    name: "Bot",
    targets: [
        Target(
            name: "Bot",
            dependencies: [
            ]
        )
    ],
    dependencies: [
        .Package(url: "https://github.com/ChameleonBot/Common.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/ChameleonBot/Config.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/ChameleonBot/Models.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/ChameleonBot/Services.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/ChameleonBot/WebAPI.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/ChameleonBot/RTMAPI.git", majorVersion: 0, minor: 2),
    ],
    exclude: [
        "XcodeProject"
    ]
)
