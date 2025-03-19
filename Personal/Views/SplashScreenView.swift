//
//  SplashScreenView.swift
//  Drona
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation = 0.0
    @State private var showTagline = false
    @State private var showCircles = false
    @State private var pulsate = false
    @State private var particleSystem = ParticleSystem()
    @State private var progress: CGFloat = 0.0
    
    @EnvironmentObject var userProfileManager: UserProfileManager
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Particles effect
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    particleSystem.update(date: timeline.date)
                    particleSystem.render(in: context, size: size)
                }
            }
            .opacity(0.6)
            .allowsHitTesting(false)
            
            // Animated circles in background
            if showCircles {
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
                            .frame(width: 300 + CGFloat(i * 80), height: 300 + CGFloat(i * 80))
                            .scaleEffect(pulsate ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                value: pulsate
                            )
                    }
                }
                .onAppear {
                    pulsate = true
                }
            }
            
            VStack(spacing: 20) {
                Spacer()
                
                // App logo / icon
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(rotation))
                        .offset(y: -5)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                    
                    withAnimation(.easeInOut(duration: 1.2).delay(0.4)) {
                        rotation = 10
                    }
                    
                    withAnimation(.easeInOut(duration: 0.8).delay(0.6)) {
                        showCircles = true
                    }
                    
                    withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
                        showTagline = true
                    }
                    
                    // Start particle system
                    particleSystem.center = UnitPoint(x: 0.5, y: 0.5)
                    
                    // Animate progress bar
                    withAnimation(.easeInOut(duration: 2.5)) {
                        progress = 1.0
                    }
                }
                
                // App name
                Text("DRONA")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
                    .opacity(opacity)
                
                // Tagline
                if showTagline {
                    Text("Your Personal AI Learning Companion")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer()
                
                // Progress indicator
                if showTagline {
                    VStack(spacing: 8) {
                        // Progress bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 200, height: 4)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .frame(width: 200 * progress, height: 4)
                        }
                        
                        Text("Loading your experience...")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 40)
                    .transition(.opacity)
                }
            }
            .padding()
        }
        .onAppear {
            // Navigate to next screen after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            if userProfileManager.isProfileCreated {
                MainTabView()
                    .environmentObject(userProfileManager)
            } else {
                OnboardingView()
                    .environmentObject(userProfileManager)
            }
        }
    }
}

// Particle system for background effect
struct ParticleSystem {
    struct Particle: Identifiable {
        var id = UUID()
        var position: UnitPoint
        var size: CGFloat
        var opacity: Double
        var speed: Double
        var rotation: Angle
        var rotationSpeed: Angle
        var creationDate = Date.now
        var lifetime = Double.random(in: 1...3)
    }
    
    var particles = [Particle]()
    var center = UnitPoint.center
    var lastUpdate = Date.now
    
    mutating func update(date: Date) {
        let timeInterval = date.timeIntervalSince(lastUpdate)
        lastUpdate = date
        
        // Add new particles
        if particles.count < 40 && Double.random(in: 0...1) < 0.1 {
            let newParticle = Particle(
                position: UnitPoint(
                    x: Double.random(in: 0.05...0.95),
                    y: Double.random(in: 0.05...0.95)
                ),
                size: CGFloat.random(in: 5...15),
                opacity: Double.random(in: 0.3...0.6),
                speed: Double.random(in: 0.005...0.02),
                rotation: Angle.degrees(Double.random(in: 0...360)),
                rotationSpeed: Angle.degrees(Double.random(in: -15...15))
            )
            particles.append(newParticle)
        }
        
        // Update existing particles
        for i in (0..<particles.count).reversed() {
            let age = date.timeIntervalSince(particles[i].creationDate)
            
            // Remove old particles
            if age > particles[i].lifetime {
                particles.remove(at: i)
                continue
            }
            
            // Move particles toward center
            let xDiff = center.x - particles[i].position.x
            let yDiff = center.y - particles[i].position.y
            let distanceFromCenter = sqrt(xDiff * xDiff + yDiff * yDiff)
            
            // Only move if not too close to center
            if distanceFromCenter > 0.05 {
                let angle = atan2(yDiff, xDiff)
                let speed = particles[i].speed * timeInterval * 60
                
                particles[i].position.x += Double(cos(angle)) * speed
                particles[i].position.y += Double(sin(angle)) * speed
            }
            
            // Rotate particle
            particles[i].rotation = particles[i].rotation + Angle.degrees(timeInterval * 60 * particles[i].rotationSpeed.degrees)
            
            // Fade out towards end of lifetime
            if age / particles[i].lifetime > 0.7 {
                particles[i].opacity = particles[i].opacity * (1 - timeInterval)
            }
        }
    }
    
    func render(in context: GraphicsContext, size: CGSize) {
        for particle in particles {
            let xPos = particle.position.x * size.width
            let yPos = particle.position.y * size.height
            
            var contextCopy = context
            contextCopy.opacity = particle.opacity
            contextCopy.translateBy(x: xPos, y: yPos)
            contextCopy.rotate(by: particle.rotation)
            
            let rect = CGRect(
                x: -particle.size / 2,
                y: -particle.size / 2,
                width: particle.size,
                height: particle.size
            )
            
            contextCopy.fill(Path(ellipseIn: rect), with: .color(.white))
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
            .environmentObject(UserProfileManager())
    }
} 