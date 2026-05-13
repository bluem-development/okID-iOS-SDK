import Foundation
import CoreNFC

/// NFC Passport Reader Service
@available(iOS 13.0, *)
public class NFCPassportReaderService: NSObject {
    
    private var session: NFCTagReaderSession?
    private var continuation: CheckedContinuation<OkIDPassportData, Error>?
    private var credentials: OkIDPassportCredentials?
    
    public override init() {
        super.init()
    }

    deinit {
        // Ensure NFC session + continuation can't leak/hang if service is released mid-read.
        session?.invalidate()
        session = nil

        if let continuation = continuation {
            continuation.resume(throwing: OkIDNFCReadError.userCancelled)
            self.continuation = nil
        }
    }
    
    /// Read passport NFC chip
    public func readPassport(credentials: OkIDPassportCredentials) async throws -> OkIDPassportData {
        // Check if NFC is available
        guard NFCTagReaderSession.readingAvailable else {
            throw OkIDNFCReadError.nfcNotSupported
        }
        
        self.credentials = credentials
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: OkIDNFCReadError.userCancelled)
                    return
                }
                self.session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self)
                self.session?.alertMessage = "Hold your passport near the top of your iPhone"
                self.session?.begin()
            }
        }
    }
    
    /// Cancel reading
    public func cancel() {
        session?.invalidate()
        continuation?.resume(throwing: OkIDNFCReadError.userCancelled)
        continuation = nil
    }
    
    private func completeReading(with passportData: OkIDPassportData) {
        session?.invalidate()
        continuation?.resume(returning: passportData)
        continuation = nil
    }
    
    private func failReading(with error: Error) {
        session?.invalidate()
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

// MARK: - NFC Tag Reader Session Delegate

@available(iOS 13.0, *)
extension NFCPassportReaderService: NFCTagReaderSessionDelegate {
    
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Session became active
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let continuation = continuation {
            let nfcError = error as? NFCReaderError
            if nfcError?.code == .readerSessionInvalidationErrorUserCanceled {
                continuation.resume(throwing: OkIDNFCReadError.userCancelled)
            } else {
                continuation.resume(throwing: OkIDNFCReadError.tagConnectionLost)
            }
            self.continuation = nil
        }
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }
        
        session.connect(to: tag) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.failReading(with: OkIDNFCReadError.unknown(error))
                return
            }
            
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    let passportData = try await self.readPassportData(tag: tag)
                    self.completeReading(with: passportData)
                } catch {
                    self.failReading(with: error)
                }
            }
        }
    }
    
    private func readPassportData(tag: NFCTag) async throws -> OkIDPassportData {
        guard case .iso7816(let iso7816Tag) = tag else {
            throw OkIDNFCReadError.unsupportedDocument
        }
        
        // This is a simplified implementation
        // In production, you would use a full MRTD reader library like NFCPassportReader
        // to handle BAC/PACE authentication, data group reading, etc.
        
        // For demonstration purposes, we'll return mock data
        let personalInfo = OkIDPersonalInfo(
            documentType: "P",
            issuingState: "USA",
            documentNumber: credentials?.documentNumber,
            lastName: "DOE",
            firstName: "JOHN",
            nationality: "USA",
            dateOfBirth: credentials?.dateOfBirth,
            gender: "M",
            dateOfExpiry: credentials?.dateOfExpiry
        )
        
        return OkIDPassportData(
            personalInfo: personalInfo,
            photo: nil,
            dataGroupsRead: ["DG1", "DG2"],
            readAt: Date()
        )
    }
}

