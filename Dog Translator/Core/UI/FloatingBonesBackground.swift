import SwiftUI

struct FloatingBonesBackground: View {
    @State private var bones: [Bone] = (0..<8).map { _ in Bone.randomBone() }

    var body: some View {
        GeometryReader { geo in

            let gridRects = calculateGrid(size: geo.size)

            ForEach(bones.indices, id: \.self) { index in
                Image("bones")
                    .resizable()
                    .scaledToFit()
                    .frame(width: bones[index].size * 0.6, height: bones[index].size * 0.6)
                    .opacity(0.6)
                    .position(x: bones[index].x * geo.size.width, y: bones[index].y * geo.size.height)
                    .rotationEffect(.degrees(bones[index].rotation))
                    .onAppear {

                        let initialTarget = randomPointInGrid(
                            rect: gridRects[index],
                            geo: geo
                        )
                        bones[index].x = initialTarget.x
                        bones[index].y = initialTarget.y

                        withAnimation(
                            .easeInOut(duration: bones[index].speed * 2)
                            .repeatForever(autoreverses: true)
                        ) {

                            let newTarget = randomPointInGrid(
                                rect: gridRects[index],
                                geo: geo
                            )
                            bones[index].x = newTarget.x
                            bones[index].y = newTarget.y
                            bones[index].rotation += Double.random(in: -30...30)
                        }
                    }
            }
        }
    }

    private func calculateGrid(size: CGSize) -> [CGRect] {
        var rects: [CGRect] = []
        let rectWidth = size.width / 4
        let rectHeight = size.height / 2

        for y in 0..<2 {
            for x in 0..<4 {
                rects.append(CGRect(
                    x: CGFloat(x) * rectWidth,
                    y: CGFloat(y) * rectHeight,
                    width: rectWidth,
                    height: rectHeight
                ))
            }
        }
        return rects
    }

    private func randomPointInGrid(rect: CGRect, geo: GeometryProxy) -> CGPoint {

        let insetRect = rect.insetBy(dx: rect.width * 0.2, dy: rect.height * 0.2)

        let point = CGPoint(
            x: CGFloat.random(in: insetRect.minX...insetRect.maxX),
            y: CGFloat.random(in: insetRect.minY...insetRect.maxY)
        )

        return CGPoint(x: point.x / geo.size.width, y: point.y / geo.size.height)
    }
}

struct Bone: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var size: CGFloat
    var rotation: Double
    var speed: Double

    static func randomBone(initialX: Double, initialY: Double) -> Bone {
        Bone(
            x: initialX,
            y: initialY,
            size: CGFloat.random(in: 40...100),
            rotation: Double.random(in: 0...360),
            speed: Double.random(in: 10...25)
        )
    }

    static func randomBone() -> Bone {
        Bone(
            x: 0.5, y: 0.5,
            size: CGFloat.random(in: 40...100),
            rotation: Double.random(in: 0...360),
            speed: Double.random(in: 10...25)
        )
    }
}
