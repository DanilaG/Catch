import SwiftUI

struct CatchView: View {
    @StateObject var game = CatchGame()

    @Namespace private var animation
    
    @State var mainColor = Color("CardText")
    @State var cardColor = Color.red
    
    var body: some View {
        ZStack {
            VStack {
                GeometryReader { geometry in
                    head(geometry: geometry)
                    field()
                }
            }
            .blur(radius: game.isYouWin != nil ? 2 : 0)
            if game.isYouWin != nil {
                gameOverScreen()
            }
        }
        .onReceive(game.onChangeColor, perform: { realChange in
            if realChange {
                let buff = mainColor
                mainColor = cardColor
                cardColor = buff
            } else {
                mainColor = Color("CardText")
                cardColor = Color.red
            }
        })
    }
    
    @State var timeToEnd = 0.0
    private func head(geometry: GeometryProxy) -> some View {
        let fontRatio: CGFloat = 0.065
        
        return HStack {
            Text("Level: ") + Text(String(game.level))
            Spacer()
            Text("Time: ") + Text(String(Int(ceil(max(0.0, timeToEnd))))) + Text("s")
        }
        .foregroundColor(Color("HeaderText"))
        .font(.system(size: geometry.size.width * fontRatio))
        .padding()
        .onAppear() {
            timeToEnd = game.freeSeconds
        }
        .onReceive(game.onTimeUpdate, perform: { time in
            timeToEnd = time
        })
    }
    
    private func field() -> some View {
        GeometryReader { geometry in
            if game.level == 0 {
                startCard()
                    .frame(width: 200, height: 100)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

            } else {
                catchCard()
                    .frame(
                        width: geometry.size.width / 2 * CGFloat(game.buttonSize.width),
                        height: geometry.size.height / 2 * CGFloat(game.buttonSize.height)
                    )
                    .position(
                        x: (geometry.size.width / 2) * (1 + CGFloat(game.position.x)),
                        y: (geometry.size.height / 2) * (1 + CGFloat(game.position.y))
                    )
            }
        }
    }
    
    private func startCard() -> some View {
        CardView(text: "Start", color: mainColor)
            .foregroundColor(.green)
            .onTapGesture {
                withAnimation(.linear) {
                    game.start()
                }
            }
    }
    
    private func catchCard() -> some View {
        CardView(text: "Tap!", color: mainColor)
            .foregroundColor(cardColor)
            .onTapGesture {
                game.wasButtonPressed = true
            }
            .animation(.linear)
    }
    
    private func gameOverScreen() -> some View {
        VStack {
            Text("You " + ((game.isYouWin ?? true) ? "Win" : "Lose") + "!").font(.title)
            Text("Game Over.").font(.title2)
            Image(systemName: "arrow.clockwise")
                .rotationEffect(Angle(degrees: 90))
                .font(.system(size: 50))
                .imageScale(.large)
                .onTapGesture {
                    game.restart()
                }
        }
    }
}

struct CardView: View {
    let text: LocalizedStringKey
    let cornerRadius: CGFloat = 15.0
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                Text(text).position(x: geometry.size.width / 2, y: geometry.size.height / 2).font(.system(size: fontRatio * geometry.size.width))
                    .foregroundColor(color)
            }
        }
    }
    
    let fontRatio: CGFloat = 0.25
}

struct CatchView_Previews: PreviewProvider {
    static var previews: some View {
        CatchView()
    }
}
