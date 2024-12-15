import ProjectDescription

let infoPlist: [String: Plist.Value] = [
    "CFBundleIdentifier": .string("io.tuist.OpenWith"),
    "CFBundleName": .string("OpenWith"),
    "CFBundleShortVersionString": .string("1.0.0"),
    "CFBundleVersion": .string("1"),
    "NSHighResolutionCapable": .boolean(true),
    "NSAppleEventsUsageDescription": .string("需要访问权限以管理文件类型关联。"),
    "LSMinimumSystemVersion": .string("14.0"),
]

let project = Project(
    name: "OpenWith",
    targets: [
        .target(
            name: "OpenWith",
            destinations: .macOS,
            product: .app,
            bundleId: "io.tuist.OpenWith",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: infoPlist),
            sources: ["OpenWith/Sources/**"],
            resources: ["OpenWith/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "OpenWithTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "io.tuist.OpenWithTests",
            infoPlist: .default,
            sources: ["OpenWith/Tests/**"],
            resources: ["OpenWith/Resources/**"],
            dependencies: [.target(name: "OpenWith")]
        ),
    ]
)
