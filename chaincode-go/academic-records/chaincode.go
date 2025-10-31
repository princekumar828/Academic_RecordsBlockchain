package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"regexp"
	"strings"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing academic records
type SmartContract struct {
	contractapi.Contract
}

// Student represents a student in the system (Enhanced for Production)
type Student struct {
	StudentID        string    `json:"studentId"`
	Name             string    `json:"name"`
	Department       string    `json:"department"`
	EnrollmentYear   int       `json:"enrollmentYear"`
	RollNumber       string    `json:"rollNumber"`        // Primary ID
	Email            string    `json:"email"`             // Must be @student.nitw.ac.in
	Phone            string    `json:"phone,omitempty"`   // Optional, modifiable
	PersonalEmail    string    `json:"personalEmail,omitempty"` // Optional, modifiable
	AadhaarHash      string    `json:"aadhaarHash"`       // SHA256 hash of Aadhaar
	AdmissionCategory string   `json:"admissionCategory"` // GEN, OBC, SC, ST, etc.
	Status           string    `json:"status"`            // ACTIVE, GRADUATED, WITHDRAWN, CANCELLED, TEMPORARY_WITHDRAWAL
	CreatedBy        string    `json:"createdBy"`
	CreatedAt        time.Time `json:"createdAt"`
	ModifiedBy       string    `json:"modifiedBy,omitempty"`
	ModifiedAt       time.Time `json:"modifiedAt,omitempty"`
}

// Course represents a single course (Enhanced with validation)
type Course struct {
	CourseCode string  `json:"courseCode"`
	CourseName string  `json:"courseName"`
	Credits    float64 `json:"credits"` // 0.5-6 credits
	Grade      string  `json:"grade"`   // S, A, B, C, D, P, U, R
	FacultyID  string  `json:"facultyId"`
}

// AcademicRecord represents semester academic records (Enhanced)
type AcademicRecord struct {
	RecordID      string    `json:"recordId"`
	StudentID     string    `json:"studentId"`
	Department    string    `json:"department"` // For department-level access control
	Semester      int       `json:"semester"`
	Courses       []Course  `json:"courses"`
	TotalCredits  float64   `json:"totalCredits"`
	SGPA          float64   `json:"sgpa"`
	CGPA          float64   `json:"cgpa"`
	Timestamp     time.Time `json:"timestamp"`
	SubmittedBy   string    `json:"submittedBy"`   // Faculty who submitted
	ApprovedBy    string    `json:"approvedBy"`    // Dean/Registrar who approved
	Status        string    `json:"status"`        // DRAFT, SUBMITTED, APPROVED
	RejectionNote string    `json:"rejectionNote,omitempty"` // If sent back for corrections
}

// Certificate represents a certificate issued to a student (Enhanced)
type Certificate struct {
	CertificateID string    `json:"certificateId"`
	StudentID     string    `json:"studentId"`
	Type          string    `json:"type"` // DEGREE, TRANSCRIPT, PROVISIONAL, BONAFIDE, MIGRATION, CHARACTER, STUDY_CONDUCT
	IssueDate     time.Time `json:"issueDate"`
	ExpiryDate    time.Time `json:"expiryDate,omitempty"` // For BONAFIDE
	PDFHash       string    `json:"pdfHash"`
	IPFSHash      string    `json:"ipfsHash"`
	IssuedBy      string    `json:"issuedBy"`
	Verified      bool      `json:"verified"`
	Revoked       bool      `json:"revoked,omitempty"`
	RevokedBy     string    `json:"revokedBy,omitempty"`
	RevokedAt     time.Time `json:"revokedAt,omitempty"`
	RevocationReason string `json:"revocationReason,omitempty"`
}

// Constants for validation
const (
	// Valid student statuses
	StatusActive              = "ACTIVE"
	StatusGraduated          = "GRADUATED"
	StatusWithdrawn          = "WITHDRAWN"
	StatusCancelled          = "CANCELLED"
	StatusTemporaryWithdrawal = "TEMPORARY_WITHDRAWAL"

	// Valid record statuses
	RecordDraft     = "DRAFT"
	RecordSubmitted = "SUBMITTED"
	RecordApproved  = "APPROVED"
	StatusDraft     = "DRAFT" // Alias for consistency

	// Valid grades (10-point scale: S,A,B,C,D,P,U,R)
	GradeS = "S" // 10 points - Outstanding
	GradeA = "A" // 9 points  - Excellent
	GradeB = "B" // 8 points  - Very Good
	GradeC = "C" // 7 points  - Good
	GradeD = "D" // 6 points  - Satisfactory
	GradeP = "P" // 5 points  - Pass
	GradeU = "U" // 0 points  - Unsatisfactory/Fail
	GradeR = "R" // 0 points  - Repeat (Attendance shortage)

	// Credit limits
	MinCredits = 0.5
	MaxCredits = 6.0

	// Semester limits
	MinSemesterCredits = 16.0
	MaxSemesterCredits = 30.0

	// Organization MSP IDs
	NITWarangalMSP = "NITWarangalMSP"
	DepartmentsMSP = "DepartmentsMSP"
	VerifiersMSP   = "VerifiersMSP"

	// Certificate types
	CertDegree        = "DEGREE"
	CertTranscript    = "TRANSCRIPT"
	CertProvisional   = "PROVISIONAL"
	CertBonafide      = "BONAFIDE"
	CertMigration     = "MIGRATION"
	CertCharacter     = "CHARACTER"
	CertStudyConduct  = "STUDY_CONDUCT"
)

// Validation helper functions

// validateEmail checks if email is valid NIT Warangal student email
func validateEmail(email string) error {
	if !strings.HasSuffix(email, "@student.nitw.ac.in") {
		return fmt.Errorf("email must be @student.nitw.ac.in domain")
	}
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@student\.nitw\.ac\.in$`)
	if !emailRegex.MatchString(email) {
		return fmt.Errorf("invalid email format")
	}
	return nil
}

// validateGrade checks if grade is valid
func validateGrade(grade string) error {
	validGrades := []string{GradeS, GradeA, GradeB, GradeC, GradeD, GradeP, GradeU, GradeR}
	for _, vg := range validGrades {
		if grade == vg {
			return nil
		}
	}
	return fmt.Errorf("invalid grade '%s'. Valid grades: S, A, B, C, D, P, U, R", grade)
}

// validateCredits checks if credit value is valid
func validateCredits(credits float64) error {
	if credits < MinCredits || credits > MaxCredits {
		return fmt.Errorf("credits must be between %.1f and %.1f", MinCredits, MaxCredits)
	}
	return nil
}

// validateSemester checks if semester number is valid (1-8 for B.Tech)
func validateSemester(semester int) error {
	if semester < 1 || semester > 8 {
		return fmt.Errorf("semester must be between 1 and 8")
	}
	return nil
}

// validateStatus checks if status is valid
func validateStatus(status string) error {
	validStatuses := []string{StatusActive, StatusGraduated, StatusWithdrawn, StatusCancelled, StatusTemporaryWithdrawal}
	for _, vs := range validStatuses {
		if status == vs {
			return nil
		}
	}
	return fmt.Errorf("invalid status '%s'", status)
}

// validateCertificateType checks if certificate type is valid
func validateCertificateType(certType string) error {
	validTypes := []string{CertDegree, CertTranscript, CertProvisional, CertBonafide, CertMigration, CertCharacter, CertStudyConduct}
	for _, vt := range validTypes {
		if certType == vt {
			return nil
		}
	}
	return fmt.Errorf("invalid certificate type '%s'", certType)
}

// Access control helper functions

// checkMSPAccess verifies if caller is from allowed organization
func checkMSPAccess(ctx contractapi.TransactionContextInterface, allowedMSPs ...string) error {
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get client MSP ID: %v", err)
	}

	for _, msp := range allowedMSPs {
		if clientMSPID == msp {
			return nil
		}
	}
	return fmt.Errorf("unauthorized: only %v can perform this operation", allowedMSPs)
}

// checkDepartmentAccess verifies if caller can access department-specific data
func checkDepartmentAccess(ctx contractapi.TransactionContextInterface, department string) error {
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get client MSP ID: %v", err)
	}

	// NITWarangalMSP has access to all departments
	if clientMSPID == NITWarangalMSP {
		return nil
	}

	// DepartmentsMSP can only access their own department
	if clientMSPID == DepartmentsMSP {
		// Get department from client certificate attribute
		dept, found, err := ctx.GetClientIdentity().GetAttributeValue("department")
		if err != nil || !found {
			return fmt.Errorf("department attribute not found in client certificate")
		}
		if dept != department {
			return fmt.Errorf("unauthorized: cannot access records from department %s", department)
		}
		return nil
	}

	return fmt.Errorf("unauthorized")
}

// InitLedger initializes the ledger with sample data
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	fmt.Println("Initializing NIT Warangal Academic Records Blockchain - Production Version")
	
	// Emit initialization event
	err := ctx.GetStub().SetEvent("LedgerInitialized", []byte(time.Now().String()))
	if err != nil {
		return fmt.Errorf("failed to set event: %v", err)
	}
	
	return nil
}

// CreateStudent creates a new student record (Enhanced with validation and RBAC)
func (s *SmartContract) CreateStudent(ctx contractapi.TransactionContextInterface,
	rollNumber, name, department string, enrollmentYear int, email, aadhaarHash, admissionCategory string) error {

	// Access Control: Only NITWarangalMSP can create students
	err := checkMSPAccess(ctx, NITWarangalMSP)
	if err != nil {
		return err
	}

	// Validate email
	err = validateEmail(email)
	if err != nil {
		return err
	}

	// Validate enrollment year (must be reasonable)
	currentYear := time.Now().Year()
	if enrollmentYear < 1950 || enrollmentYear > currentYear+1 {
		return fmt.Errorf("invalid enrollment year %d", enrollmentYear)
	}

	// Validate name
	if len(name) < 3 || len(name) > 100 {
		return fmt.Errorf("name must be between 3 and 100 characters")
	}

	// Validate roll number format
	if len(rollNumber) < 5 || len(rollNumber) > 20 {
		return fmt.Errorf("roll number must be between 5 and 20 characters")
	}

	// Check if student already exists (using rollNumber as primary key)
	exists, err := s.StudentExists(ctx, rollNumber)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("student with roll number %s already exists", rollNumber)
	}

	// Get transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Get creator ID
	clientID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client identity: %v", err)
	}

	student := Student{
		StudentID:        rollNumber, // Using rollNumber as studentID
		Name:             name,
		Department:       department,
		EnrollmentYear:   enrollmentYear,
		RollNumber:       rollNumber,
		Email:            email,
		Phone:            "", // Empty initially, can be updated later
		PersonalEmail:    "", // Empty initially, can be updated later
		AadhaarHash:      aadhaarHash,
		AdmissionCategory: admissionCategory,
		Status:           StatusActive,
		CreatedBy:        clientID,
		CreatedAt:        timestamp,
		ModifiedBy:       clientID,
		ModifiedAt:       timestamp,
	}

	studentJSON, err := json.Marshal(student)
	if err != nil {
		return err
	}

	// Store with primary key (rollNumber)
	err = ctx.GetStub().PutState(rollNumber, studentJSON)
	if err != nil {
		return err
	}

	// Create composite keys for efficient querying
	// 1. student~department~rollNumber (for department-wise queries)
	deptKey, err := ctx.GetStub().CreateCompositeKey("student~dept", []string{department, rollNumber})
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(deptKey, studentJSON)
	if err != nil {
		return err
	}

	// 2. student~year~rollNumber (for year-wise queries)
	yearKey, err := ctx.GetStub().CreateCompositeKey("student~year", []string{fmt.Sprintf("%d", enrollmentYear), rollNumber})
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(yearKey, studentJSON)
	if err != nil {
		return err
	}

	// 3. student~status~rollNumber (for status-wise queries)
	statusKey, err := ctx.GetStub().CreateCompositeKey("student~status", []string{StatusActive, rollNumber})
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(statusKey, studentJSON)
	if err != nil {
		return err
	}

	// Emit student created event
	eventPayload := map[string]interface{}{
		"rollNumber":     rollNumber,
		"name":           name,
		"department":     department,
		"enrollmentYear": enrollmentYear,
		"createdBy":      clientID,
		"createdAt":      timestamp,
	}
	eventJSON, _ := json.Marshal(eventPayload)
	err = ctx.GetStub().SetEvent("StudentCreated", eventJSON)
	if err != nil {
		return fmt.Errorf("failed to set event: %v", err)
	}

	return nil
}

// GetStudent retrieves a student record (Enhanced with department-level access control)
func (s *SmartContract) GetStudent(ctx contractapi.TransactionContextInterface, rollNumber string) (*Student, error) {
	studentJSON, err := ctx.GetStub().GetState(rollNumber)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if studentJSON == nil {
		return nil, fmt.Errorf("student %s does not exist", rollNumber)
	}

	var student Student
	err = json.Unmarshal(studentJSON, &student)
	if err != nil {
		return nil, err
	}

	// Access Control: Check department access for DepartmentsMSP
	err = checkDepartmentAccess(ctx, student.Department)
	if err != nil {
		return nil, err
	}

	return &student, nil
}

// UpdateStudentStatus updates the status of a student (Enhanced with RBAC and approval)
func (s *SmartContract) UpdateStudentStatus(ctx contractapi.TransactionContextInterface,
	rollNumber, newStatus, reason string) error {

	// Access Control: Only NITWarangalMSP can update status
	err := checkMSPAccess(ctx, NITWarangalMSP)
	if err != nil {
		return err
	}

	// Validate new status
	err = validateStatus(newStatus)
	if err != nil {
		return err
	}

	student, err := s.GetStudent(ctx, rollNumber)
	if err != nil {
		return err
	}

	oldStatus := student.Status

	// Critical status changes (CANCELLED, WITHDRAWN) require reason
	if (newStatus == StatusCancelled || newStatus == StatusWithdrawn) && reason == "" {
		return fmt.Errorf("reason required for status change to %s", newStatus)
	}

	// Get transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Get modifier ID
	clientID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client identity: %v", err)
	}

	student.Status = newStatus
	student.ModifiedBy = clientID
	student.ModifiedAt = timestamp

	studentJSON, err := json.Marshal(student)
	if err != nil {
		return err
	}

	// Update main record
	err = ctx.GetStub().PutState(rollNumber, studentJSON)
	if err != nil {
		return err
	}

	// Update status composite key
	// Remove old status key
	oldStatusKey, err := ctx.GetStub().CreateCompositeKey("student~status", []string{oldStatus, rollNumber})
	if err == nil {
		ctx.GetStub().DelState(oldStatusKey)
	}

	// Add new status key
	newStatusKey, err := ctx.GetStub().CreateCompositeKey("student~status", []string{newStatus, rollNumber})
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(newStatusKey, studentJSON)
	if err != nil {
		return err
	}

	// Emit status change event
	eventPayload := map[string]interface{}{
		"rollNumber": rollNumber,
		"oldStatus":  oldStatus,
		"newStatus":  newStatus,
		"reason":     reason,
		"modifiedBy": clientID,
		"modifiedAt": timestamp,
	}
	eventJSON, _ := json.Marshal(eventPayload)
	err = ctx.GetStub().SetEvent("StudentStatusChanged", eventJSON)
	if err != nil {
		return fmt.Errorf("failed to set event: %v", err)
	}

	return nil
}

// UpdateStudentContactInfo updates modifiable contact information
func (s *SmartContract) UpdateStudentContactInfo(ctx contractapi.TransactionContextInterface,
	rollNumber, phone, personalEmail string) error {

	// Access Control: Only NITWarangalMSP can update
	err := checkMSPAccess(ctx, NITWarangalMSP)
	if err != nil {
		return err
	}

	student, err := s.GetStudent(ctx, rollNumber)
	if err != nil {
		return err
	}

	// Get transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Get modifier ID
	clientID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client identity: %v", err)
	}

	// Update only modifiable fields
	if phone != "" {
		student.Phone = phone
	}
	if personalEmail != "" {
		student.PersonalEmail = personalEmail
	}
	student.ModifiedBy = clientID
	student.ModifiedAt = timestamp

	studentJSON, err := json.Marshal(student)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(rollNumber, studentJSON)
}

// StudentExists checks if a student exists
func (s *SmartContract) StudentExists(ctx contractapi.TransactionContextInterface, studentID string) (bool, error) {
	studentJSON, err := ctx.GetStub().GetState(studentID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return studentJSON != nil, nil
}

// CreateAcademicRecord creates a new academic record (Enhanced with validation and access control)
func (s *SmartContract) CreateAcademicRecord(ctx contractapi.TransactionContextInterface,
	recordID, rollNumber string, semester int, year string, department string, coursesJSON string) error {

	// Access Control: Only DepartmentsMSP or NITWarangalMSP can create records
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}
	
	if mspID != NITWarangalMSP {
		// Department users can only create records for their department
		err = checkDepartmentAccess(ctx, department)
		if err != nil {
			return fmt.Errorf("access denied: %v", err)
		}
	}

	// Check if record already exists
	recordJSON, err := ctx.GetStub().GetState(recordID)
	if err != nil {
		return fmt.Errorf("failed to read record: %v", err)
	}
	if recordJSON != nil {
		return fmt.Errorf("academic record %s already exists", recordID)
	}

	// Verify student exists
	exists, err := s.StudentExists(ctx, rollNumber)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("student %s does not exist", rollNumber)
	}

	// Validate semester (1-8)
	if err := validateSemester(semester); err != nil {
		return err
	}

	var courses []Course
	err = json.Unmarshal([]byte(coursesJSON), &courses)
	if err != nil {
		return fmt.Errorf("failed to parse courses: %v", err)
	}

	if len(courses) == 0 {
		return fmt.Errorf("at least one course is required")
	}

	// Validate each course and calculate total credits
	totalCredits := 0.0
	for i, course := range courses {
		// Validate course code
		if len(course.CourseCode) < 3 || len(course.CourseCode) > 20 {
			return fmt.Errorf("course %d: invalid course code length (must be 3-20 characters)", i+1)
		}

		// Validate course name
		if len(course.CourseName) < 3 || len(course.CourseName) > 100 {
			return fmt.Errorf("course %d: invalid course name length (must be 3-100 characters)", i+1)
		}

		// Validate credits (0.5-6)
		if err := validateCredits(course.Credits); err != nil {
			return fmt.Errorf("course %d (%s): %v", i+1, course.CourseCode, err)
		}

		// Validate grade (S, A, B, C, D, P, U, R)
		if err := validateGrade(course.Grade); err != nil {
			return fmt.Errorf("course %d (%s): %v", i+1, course.CourseCode, err)
		}

		totalCredits += course.Credits
	}

	// Validate total credits per semester (16-30)
	if totalCredits < 16.0 || totalCredits > 30.0 {
		return fmt.Errorf("total semester credits %.1f out of range (must be 16-30)", totalCredits)
	}

	// Calculate GPA for this semester
	_, sgpa := calculateGrades(courses)

	clientID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client identity: %v", err)
	}

	// Get transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Create academic record with DRAFT status initially
	record := AcademicRecord{
		RecordID:     recordID,
		StudentID:    rollNumber, // Using rollNumber as student identifier
		Department:   department,
		Semester:     semester,
		Courses:      courses,
		TotalCredits: totalCredits,
		SGPA:         sgpa,
		CGPA:         0.0, // Will be calculated on approval
		Timestamp:    timestamp,
		SubmittedBy:  clientID,
		Status:       StatusDraft,
		ApprovedBy:   "",
	}

	recordJSONBytes, err := json.Marshal(record)
	if err != nil {
		return err
	}

	// Store with primary key
	err = ctx.GetStub().PutState(recordID, recordJSONBytes)
	if err != nil {
		return err
	}

	// Create composite keys for efficient querying
	// 1. student~record
	studentRecordKey, err := ctx.GetStub().CreateCompositeKey("student~record", []string{rollNumber, recordID})
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(studentRecordKey, []byte{0x00})
	if err != nil {
		return err
	}

	// 2. record~semester~student
	recordSemesterKey, err := ctx.GetStub().CreateCompositeKey("record~semester~student", []string{
		fmt.Sprintf("%d", semester), rollNumber, recordID,
	})
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(recordSemesterKey, []byte{0x00})
	if err != nil {
		return err
	}

	// 3. record~status~student
	recordStatusKey, err := ctx.GetStub().CreateCompositeKey("record~status~student", []string{
		record.Status, rollNumber, recordID,
	})
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(recordStatusKey, []byte{0x00})
	if err != nil {
		return err
	}

	// 4. record~department
	recordDeptKey, err := ctx.GetStub().CreateCompositeKey("record~department", []string{
		department, recordID,
	})
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(recordDeptKey, []byte{0x00})
	if err != nil {
		return err
	}

	// Emit event
	eventPayload := map[string]interface{}{
		"recordID":     recordID,
		"rollNumber":   rollNumber,
		"semester":     semester,
		"year":         year,
		"department":   department,
		"coursesCount": len(courses),
		"totalCredits": totalCredits,
		"sgpa":         sgpa,
		"status":       record.Status,
		"submittedBy":  clientID,
		"timestamp":    timestamp.Format("2006-01-02T15:04:05Z07:00"),
	}
	eventJSONBytes, _ := json.Marshal(eventPayload)
	ctx.GetStub().SetEvent("RecordCreated", eventJSONBytes)

	return nil
}

// GetAcademicRecord retrieves an academic record (Enhanced with department access control)
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

	// Access Control: Check department access for DepartmentsMSP
	err = checkDepartmentAccess(ctx, record.Department)
	if err != nil {
		return nil, err
	}

	return &record, nil
}

// ApproveAcademicRecord approves an academic record and calculates CGPA (Enhanced with RBAC and workflow)
func (s *SmartContract) ApproveAcademicRecord(ctx contractapi.TransactionContextInterface, recordID string) error {
	// Access Control: Only NITWarangalMSP (Dean/Registrar) can approve records
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}
	if mspID != NITWarangalMSP {
		return fmt.Errorf("access denied: only NITWarangalMSP can approve academic records")
	}

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

	// Check if already approved
	if record.Status == RecordApproved {
		return fmt.Errorf("record %s is already approved", recordID)
	}

	// Record must be submitted before approval
	if record.Status != RecordSubmitted && record.Status != RecordDraft {
		return fmt.Errorf("cannot approve record with status %s", record.Status)
	}

	clientID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client identity: %v", err)
	}

	// Calculate CGPA based on all approved records for this student
	cgpa, err := s.calculateCGPA(ctx, record.StudentID, record.Semester)
	if err != nil {
		return fmt.Errorf("failed to calculate CGPA: %v", err)
	}

	// Update composite keys if status changed from non-APPROVED to APPROVED
	if record.Status != RecordApproved {
		// Remove old status composite key
		oldStatusKey, err := ctx.GetStub().CreateCompositeKey("record~status~student", []string{
			record.Status, record.StudentID, recordID,
		})
		if err == nil {
			ctx.GetStub().DelState(oldStatusKey)
		}

		// Add new status composite key
		newStatusKey, err := ctx.GetStub().CreateCompositeKey("record~status~student", []string{
			RecordApproved, record.StudentID, recordID,
		})
		if err != nil {
			return fmt.Errorf("failed to create new status composite key: %v", err)
		}
		err = ctx.GetStub().PutState(newStatusKey, []byte{0x00})
		if err != nil {
			return fmt.Errorf("failed to save new status composite key: %v", err)
		}
	}

	// Update record
	record.CGPA = cgpa
	record.Status = RecordApproved
	record.ApprovedBy = clientID

	updatedJSON, err := json.Marshal(record)
	if err != nil {
		return err
	}

	err = ctx.GetStub().PutState(recordID, updatedJSON)
	if err != nil {
		return err
	}

	// Emit event
	txTimestamp, _ := ctx.GetStub().GetTxTimestamp()
	eventPayload := map[string]interface{}{
		"recordID":   recordID,
		"studentID":  record.StudentID,
		"semester":   record.Semester,
		"department": record.Department,
		"sgpa":       record.SGPA,
		"cgpa":       cgpa,
		"approvedBy": clientID,
		"timestamp":  time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).Format("2006-01-02T15:04:05Z07:00"),
	}
	eventJSON, _ := json.Marshal(eventPayload)
	ctx.GetStub().SetEvent("RecordApproved", eventJSON)

	return nil
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

// Helper function to calculate grades (Enhanced with custom NIT Warangal grade system)
func calculateGrades(courses []Course) (float64, float64) {
	totalCredits := 0.0
	totalGradePoints := 0.0

	// Custom NIT Warangal grade point mapping (10-point scale)
	gradePoints := map[string]float64{
		GradeS: 10.0, // Outstanding
		GradeA: 9.0,  // Excellent
		GradeB: 8.0,  // Very Good
		GradeC: 7.0,  // Good
		GradeD: 6.0,  // Average
		GradeP: 5.0,  // Pass
		GradeU: 0.0,  // Fail
		GradeR: 0.0,  // Reappear
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

// Calculate CGPA based on all approved records (Enhanced)
func (s *SmartContract) calculateCGPA(ctx contractapi.TransactionContextInterface, studentID string, currentSemester int) (float64, error) {
	records, err := s.GetStudentHistory(ctx, studentID)
	if err != nil {
		return 0, err
	}

	totalCredits := 0.0
	totalGradePoints := 0.0

	for _, record := range records {
		// Only include approved records up to current semester
		if record.Status == RecordApproved && record.Semester <= currentSemester {
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
