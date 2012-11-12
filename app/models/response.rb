# Set of answers for a survey

class Response < ActiveRecord::Base
  belongs_to :survey
  has_many :answers, :dependent => :destroy
  accepts_nested_attributes_for :answers
  attr_accessible :survey, :answers_attributes, :mobile_id, :survey_id, :status, :updated_at
  validates_presence_of :survey_id
  validates_presence_of :organization_id
  validates_presence_of :user_id
  validates_associated :answers
  delegate :questions, :to => :survey
  delegate :public?, :to => :survey, :prefix => true, :allow_nil => true

  def answers_for_identifier_questions
    answers.find_all { |answer| answer.question.identifier? }
  end

  def complete
    update_attribute(:status, 'complete')
  end

  def incomplete
   update_attribute(:status, 'incomplete')
  end

  def validating
   update_attribute(:status, 'validating')
  end

  def complete?
    status == 'complete'
  end

  def incomplete?
    status == 'incomplete'
  end

  def validating?
    status == 'validating'
  end

  def set(survey_id, user_id, organization_id, session_token)
    self.survey_id = survey_id
    self.organization_id = organization_id
    self.user_id = user_id
    self.session_token = session_token
  end

  def filename_for_excel
    "#{survey.name} - #{Time.now}.xls"
  end

  def select_new_answers(answers_attributes)
    answers_attributes.reject do |_, answer_attributes|
      existing_answer = answers.find_by_id(answer_attributes['id'])
      existing_answer && (Time.parse(answer_attributes['updated_at']) < existing_answer.updated_at)
    end
  end
  
  def merge_status(params)
    return unless params[:updated_at]
    if Time.parse(params[:updated_at]) > updated_at
      case params[:status]
      when 'complete'
        complete
      when 'incomplete'
        incomplete
      end
    end
  end

  def to_json_with_answers_and_choices
    to_json(:include => {:answers => {:include => :choices}})
  end
end
