package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing academic records
type SmartContract struct {
	contractapi.Contract
}

// Student represents a student in the system
type Student struct {
	StudentID      string `json:"studentId"`
	Name           string `json:"name"`
	Department     string `json:"department"`
	EnrollmentYear int    `json:"enrollmentYear"`
	RollNumber     string `json:"rollNumber"`
	Email          string `json:"email"`
	Status         string `json:"status"` // ACTIVE, GRADUATED, SUSPENDED
}

// Course represents a single course
type Course struct {
	CourseCode string  `json:"courseCode"`
	CourseName string  `json:"courseName"`
	Credits    float64 `json:"credits"`
	Grade      string  `json:"grade"`
	FacultyID  string  `json:"facultyId"`
}

// AcademicRecord represents semester academic records
type AcademicRecord struct {
	RecordID     string    `json:"recordId"`
	StudentID    string    `json:"studentId"`
	Semester     int       `json:"semester"`
	Courses      []Course  `json:"courses"`
	TotalCredits float64   `json:"totalCredits"`
	SGPA         float64   `json:"sgpa"`
	CGPA         float64   `json:"cgpa"`
	Timestamp    time.Time `json:"timestamp"`
	SubmittedBy  string    `json:"submittedBy"`
	ApprovedBy   string    `json:"approvedBy"`
	Status       string    `json:"status"` // DRAFT, SUBMITTED, APPROVED
}

// Certificate represents a certificate issued to a student
type Certificate struct {
	CertificateID string    `json:"certificateId"`
	StudentID     string    `json:"studentId"`
	Type          string    `json:"type"` // DEGREE, TRANSCRIPT, PROVISIONAL, BONAFIDE
	IssueDate     time.Time `json:"issueDate"`
	PDFHash       string    `json:"pdfHash"`
	IPFSHash      string    `json:"ipfsHash"`
	IssuedBy      string    `json:"issuedBy"`
	Verified      bool      `json:"verified"`
}

// InitLedger initializes the ledger with sample data
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	fmt.Println("Initializing NIT Warangal Academic Records Blockchain")
	return nil
}

// CreateStudent creates a new student record
func (s *SmartContract) CreateStudent(ctx contractapi.TransactionContextInterface,
	studentID, name, department string, enrollmentYear int, rollNumber, email string) error {

	exists, err := s.StudentExists(ctx, studentID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("student %s already exists", studentID)
	}

	student := Student{
		StudentID:      studentID,
		Name:           name,
		Department:     department,
		EnrollmentYear: enrollmentYear,
		RollNumber:     rollNumber,
		Email:          email,
		Status:         "ACTIVE",
	}

	studentJSON, err := json.Marshal(student)
	if err != nil {
		return err
	}

	// Store with primary key
	err = ctx.GetStub().PutState(studentID, studentJSON)
	if err != nil {
		return err
	}

	// Create composite key for querying all students
	compositeKey, err := ctx.GetStub().CreateCompositeKey("student", []string{studentID})
	if err != nil {
		return err
	}

	// Store composite key (value is the student data for efficient retrieval)
	return ctx.GetStub().PutState(compositeKey, studentJSON)
}

// GetStudent retrieves a student record
func (s *SmartContract) GetStudent(ctx contractapi.TransactionContextInterface, studentID string) (*Student, error) {
	studentJSON, err := ctx.GetStub().GetState(studentID)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if studentJSON == nil {
		return nil, fmt.Errorf("student %s does not exist", studentID)
	}

	var student Student
	err = json.Unmarshal(studentJSON, &student)
	if err != nil {
		return nil, err
	}

	return &student, nil
}

// UpdateStudentStatus updates the status of a student
func (s *SmartContract) UpdateStudentStatus(ctx contractapi.TransactionContextInterface,
	studentID, newStatus string) error {

	student, err := s.GetStudent(ctx, studentID)
	if err != nil {
		return err
	}

	student.Status = newStatus

	studentJSON, err := json.Marshal(student)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(studentID, studentJSON)
}

// StudentExists checks if a student exists
func (s *SmartContract) StudentExists(ctx contractapi.TransactionContextInterface, studentID string) (bool, error) {
	studentJSON, err := ctx.GetStub().GetState(studentID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return studentJSON != nil, nil
}

// CreateAcademicRecord creates a new academic record for a semester
func (s *SmartContract) CreateAcademicRecord(ctx contractapi.TransactionContextInterface,
	recordID, studentID string, semester int, coursesJSON string) error {

	exists, err := s.StudentExists(ctx, studentID)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("student %s does not exist", studentID)
	}

	var courses []Course
	err = json.Unmarshal([]byte(coursesJSON), &courses)
	if err != nil {
		return fmt.Errorf("failed to parse courses: %v", err)
	}

	totalCredits, sgpa := calculateGrades(courses)

	clientID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client identity: %v", err)
	}

	// Get transaction timestamp for deterministic behavior
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	record := AcademicRecord{
		RecordID:     recordID,
		StudentID:    studentID,
		Semester:     semester,
		Courses:      courses,
		TotalCredits: totalCredits,
		SGPA:         sgpa,
		CGPA:         0, // Will be calculated when approved
		Timestamp:    timestamp,
		SubmittedBy:  clientID,
		Status:       "DRAFT",
	}

	recordJSON, err := json.Marshal(record)
	if err != nil {
		return err
	}

	// Store with primary key
	err = ctx.GetStub().PutState(recordID, recordJSON)
	if err != nil {
		return err
	}

	// Create composite key for querying by studentID
	compositeKey, err := ctx.GetStub().CreateCompositeKey("student~record", []string{studentID, recordID})
	if err != nil {
		return err
	}

	// Store composite key (value can be empty as we only use it for indexing)
	return ctx.GetStub().PutState(compositeKey, recordJSON)
}

// GetAcademicRecord retrieves an academic record
func (s *SmartContract) GetAcademicRecord(ctx contractapi.TransactionContextInterface, recordID string) (*AcademicRecord, error) {
	recordJSON, err := ctx.GetStub().GetState(recordID)
	if err != nil {
		return nil, fmt.Errorf("failed to read record: %v", err)
	}
	if recordJSON == nil {
		return nil, fmt.Errorf("record %s does not exist", recordID)
	}

	var record AcademicRecord
	err = json.Unmarshal(recordJSON, &record)
	if err != nil {
		return nil, err
	}

	return &record, nil
}

// ApproveAcademicRecord approves an academic record and calculates CGPA
func (s *SmartContract) ApproveAcademicRecord(ctx contractapi.TransactionContextInterface, recordID string) error {
	recordJSON, err := ctx.GetStub().GetState(recordID)
	if err != nil {
		return fmt.Errorf("failed to read record: %v", err)
	}
	if recordJSON == nil {
		return fmt.Errorf("record %s does not exist", recordID)
	}

	var record AcademicRecord
	err = json.Unmarshal(recordJSON, &record)
	if err != nil {
		return err
	}

	if record.Status == "APPROVED" {
		return fmt.Errorf("record %s is already approved", recordID)
	}

	clientID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client identity: %v", err)
	}

	// Calculate CGPA based on all previous records
	cgpa, err := s.calculateCGPA(ctx, record.StudentID, record.Semester)
	if err != nil {
		return err
	}

	record.CGPA = cgpa
	record.Status = "APPROVED"
	record.ApprovedBy = clientID

	recordJSON, err = json.Marshal(record)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(recordID, recordJSON)
}

// IssueCertificate issues a certificate with PDF hash
func (s *SmartContract) IssueCertificate(ctx contractapi.TransactionContextInterface,
	certificateID, studentID, certType, pdfBase64, ipfsHash string) error {

	exists, err := s.StudentExists(ctx, studentID)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("student %s does not exist", studentID)
	}

	// Calculate hash of PDF
	hash := sha256.Sum256([]byte(pdfBase64))
	pdfHash := hex.EncodeToString(hash[:])

	clientID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client identity: %v", err)
	}

	// Get transaction timestamp for deterministic behavior
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	issueDate := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	certificate := Certificate{
		CertificateID: certificateID,
		StudentID:     studentID,
		Type:          certType,
		IssueDate:     issueDate,
		PDFHash:       pdfHash,
		IPFSHash:      ipfsHash,
		IssuedBy:      clientID,
		Verified:      true,
	}

	certJSON, err := json.Marshal(certificate)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(certificateID, certJSON)
}

// GetCertificate retrieves a certificate
func (s *SmartContract) GetCertificate(ctx contractapi.TransactionContextInterface,
	certificateID string) (*Certificate, error) {

	certJSON, err := ctx.GetStub().GetState(certificateID)
	if err != nil {
		return nil, fmt.Errorf("failed to read certificate: %v", err)
	}
	if certJSON == nil {
		return nil, fmt.Errorf("certificate %s does not exist", certificateID)
	}

	var certificate Certificate
	err = json.Unmarshal(certJSON, &certificate)
	if err != nil {
		return nil, err
	}

	return &certificate, nil
}

// VerifyCertificate verifies a certificate by comparing PDF hash
func (s *SmartContract) VerifyCertificate(ctx contractapi.TransactionContextInterface,
	certificateID, pdfBase64 string) (bool, error) {

	certJSON, err := ctx.GetStub().GetState(certificateID)
	if err != nil {
		return false, fmt.Errorf("failed to read certificate: %v", err)
	}
	if certJSON == nil {
		return false, fmt.Errorf("certificate %s does not exist", certificateID)
	}

	var certificate Certificate
	err = json.Unmarshal(certJSON, &certificate)
	if err != nil {
		return false, err
	}

	// Calculate hash of provided PDF
	hash := sha256.Sum256([]byte(pdfBase64))
	providedHash := hex.EncodeToString(hash[:])

	return providedHash == certificate.PDFHash, nil
}

// GetStudentHistory retrieves all academic records for a student
func (s *SmartContract) GetStudentHistory(ctx contractapi.TransactionContextInterface, studentID string) ([]*AcademicRecord, error) {
	// Use composite key to query records by studentID
	// Format: student~record~{studentID}~{recordID}
	resultsIterator, err := ctx.GetStub().GetStateByPartialCompositeKey("student~record", []string{studentID})
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var records []*AcademicRecord
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var record AcademicRecord
		err = json.Unmarshal(queryResponse.Value, &record)
		if err != nil {
			return nil, err
		}
		records = append(records, &record)
	}

	return records, nil
}

// GetAllStudents retrieves all students
func (s *SmartContract) GetAllStudents(ctx contractapi.TransactionContextInterface) ([]*Student, error) {
	// Use composite key to query all students
	// Format: student~{studentID}
	resultsIterator, err := ctx.GetStub().GetStateByPartialCompositeKey("student", []string{})
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var students []*Student
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var student Student
		err = json.Unmarshal(queryResponse.Value, &student)
		if err != nil {
			return nil, err
		}
		students = append(students, &student)
	}

	return students, nil
}

// Helper function to calculate grades
func calculateGrades(courses []Course) (float64, float64) {
	totalCredits := 0.0
	totalGradePoints := 0.0

	gradePoints := map[string]float64{
		"S": 10, "A": 9, "B": 8, "C": 7, "D": 6, "E": 5, "F": 0,
	}

	for _, course := range courses {
		totalCredits += course.Credits
		if gp, ok := gradePoints[course.Grade]; ok {
			totalGradePoints += gp * course.Credits
		}
	}

	sgpa := 0.0
	if totalCredits > 0 {
		sgpa = totalGradePoints / totalCredits
	}

	return totalCredits, sgpa
}

// Calculate CGPA
func (s *SmartContract) calculateCGPA(ctx contractapi.TransactionContextInterface, studentID string, currentSemester int) (float64, error) {
	records, err := s.GetStudentHistory(ctx, studentID)
	if err != nil {
		return 0, err
	}

	totalCredits := 0.0
	totalGradePoints := 0.0

	for _, record := range records {
		if record.Status == "APPROVED" && record.Semester <= currentSemester {
			totalCredits += record.TotalCredits
			totalGradePoints += record.SGPA * record.TotalCredits
		}
	}

	cgpa := 0.0
	if totalCredits > 0 {
		cgpa = totalGradePoints / totalCredits
	}

	return cgpa, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating academic records chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting academic records chaincode: %v\n", err)
	}
}
